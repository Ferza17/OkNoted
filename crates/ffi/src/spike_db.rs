//! M1 spike: one SQLite connection, persisted in OPFS on web and in a file on native.
//!
//! On web the connection lives on a single Web Worker: the OPFS pool only works in
//! a dedicated worker, is owned per worker, and SQLite is built single-threaded.
//! [`init`] must therefore run on a worker (a plain frb function); later calls send
//! jobs to that worker over a channel. See ADR 0007.

use rusqlite::Connection;

const CREATE_TABLE: &str =
    "CREATE TABLE IF NOT EXISTS spike_rows (id INTEGER PRIMARY KEY, body TEXT NOT NULL)";

/// Inserts `rows` rows in one transaction and returns the new total.
pub fn insert_rows(conn: &mut Connection, rows: u32) -> rusqlite::Result<u64> {
    let tx = conn.transaction()?;
    {
        let mut insert = tx.prepare("INSERT INTO spike_rows (body) VALUES (?1)")?;
        for i in 0..rows {
            insert.execute([format!("row {i}")])?;
        }
    }
    tx.commit()?;
    read_rows(conn)
}

/// Reads every row back and returns how many were read.
pub fn read_rows(conn: &mut Connection) -> rusqlite::Result<u64> {
    let mut select = conn.prepare("SELECT body FROM spike_rows")?;
    let mut rows = select.query([])?;
    let mut count = 0;
    while rows.next()?.is_some() {
        count += 1;
    }
    Ok(count)
}

fn prepare(conn: Connection) -> rusqlite::Result<Connection> {
    conn.execute(CREATE_TABLE, [])?;
    Ok(conn)
}

#[cfg(not(target_arch = "wasm32"))]
mod imp {
    use std::path::PathBuf;
    use std::sync::Mutex;

    use rusqlite::Connection;

    static DB: Mutex<Option<Connection>> = Mutex::new(None);

    fn path() -> PathBuf {
        std::env::var_os("OKNOTED_DATA_DIR")
            .map_or_else(std::env::temp_dir, PathBuf::from)
            .join("oknoted-spike.db")
    }

    pub fn init() -> Result<(), String> {
        run_now(|_| Ok(()))
    }

    pub async fn run<T: Send + 'static>(
        job: impl FnOnce(&mut Connection) -> rusqlite::Result<T> + Send + 'static,
    ) -> Result<T, String> {
        run_now(job)
    }

    fn run_now<T>(job: impl FnOnce(&mut Connection) -> rusqlite::Result<T>) -> Result<T, String> {
        let mut guard = DB.lock().map_err(|_| "database lock poisoned".to_owned())?;
        let conn = match &mut *guard {
            Some(conn) => conn,
            slot @ None => slot.insert(
                super::prepare(Connection::open(path()).map_err(|e| e.to_string())?)
                    .map_err(|e| e.to_string())?,
            ),
        };
        job(conn).map_err(|e| e.to_string())
    }
}

#[cfg(target_arch = "wasm32")]
mod imp {
    use std::sync::OnceLock;

    use futures::StreamExt;
    use futures::channel::{mpsc, oneshot};
    use rusqlite::Connection;
    use sqlite_wasm_vfs::sahpool::{OpfsSAHPoolCfg, install};

    type Job = Box<dyn FnOnce(Result<&mut Connection, &str>) + Send>;

    static JOBS: OnceLock<mpsc::UnboundedSender<Job>> = OnceLock::new();

    /// Starts the database actor on the current thread, which must be a Web Worker.
    pub fn init() -> Result<(), String> {
        let (jobs, queue) = mpsc::unbounded();
        if JOBS.set(jobs).is_ok() {
            wasm_bindgen_futures::spawn_local(actor(queue));
        }
        Ok(())
    }

    async fn actor(mut queue: mpsc::UnboundedReceiver<Job>) {
        let mut conn = open().await;
        while let Some(job) = queue.next().await {
            match &mut conn {
                Ok(conn) => job(Ok(conn)),
                Err(error) => job(Err(error)),
            }
        }
    }

    async fn open() -> Result<Connection, String> {
        install::<sqlite_wasm_rs::WasmOsCallback>(&OpfsSAHPoolCfg::default(), true)
            .await
            .map_err(|e| e.to_string())?;
        let conn = Connection::open("oknoted-spike.db").map_err(|e| e.to_string())?;
        super::prepare(conn).map_err(|e| e.to_string())
    }

    pub async fn run<T: Send + 'static>(
        job: impl FnOnce(&mut Connection) -> rusqlite::Result<T> + Send + 'static,
    ) -> Result<T, String> {
        let jobs = JOBS
            .get()
            .ok_or("database not started: call spike_sqlite_init first")?;
        let (reply, result) = oneshot::channel();
        let job: Job = Box::new(move |conn| {
            let _ = reply.send(
                conn.map_err(str::to_owned)
                    .and_then(|conn| job(conn).map_err(|e| e.to_string())),
            );
        });
        jobs.unbounded_send(job)
            .map_err(|_| "database worker stopped".to_owned())?;
        result
            .await
            .map_err(|_| "database worker dropped the job".to_owned())?
    }
}

pub use imp::{init, run};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn writes_and_reads_rows() {
        let mut conn = prepare(Connection::open_in_memory().unwrap()).unwrap();
        assert_eq!(insert_rows(&mut conn, 1000).unwrap(), 1000);
        assert_eq!(insert_rows(&mut conn, 1000).unwrap(), 2000);
        assert_eq!(read_rows(&mut conn).unwrap(), 2000);
    }
}
