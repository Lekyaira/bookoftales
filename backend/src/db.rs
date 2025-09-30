use rocket_db_pools::Database;

#[derive(Database)]
#[database("bookoftales")]
pub struct BookDB(rocket_db_pools::sqlx::PgPool);
