use rocket::{get, serde::json::Json};
use rocket_okapi::{
    okapi::{schemars, schemars::JsonSchema},
    openapi, openapi_get_routes,
    swagger_ui::{SwaggerUIConfig, make_swagger_ui},
};

pub fn get_routes() -> Vec<rocket::Route> {
    openapi_get_routes![
        test_page,
    ]
}

#[openapi]
#[get("/test")]
async fn test_page() -> Json<String> {
    format!("Hello world!").into()
}
