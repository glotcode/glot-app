import glot_frontend/admin/command as admin_effect
import glot_frontend/admin/config/section
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type MissingConfig(fields) {
  MissingConfig(code: String, fields: fields)
}

pub type Event(response) {
  LoadCompleted(Generation(section.LoadStream), api_response.Response(response))
  SaveCompleted(Generation(section.SaveStream), api_response.Response(response))
}

pub opaque type CompletionPolicy(fields, response) {
  Required(
    to_fields: fn(response) -> fields,
    load_http_failure: String,
    save_http_failure: String,
  )
  Optional(
    to_fields: fn(response) -> fields,
    missing: MissingConfig(fields),
    load_http_failure: String,
    save_http_failure: String,
  )
}

pub fn required(
  to_fields to_fields: fn(response) -> fields,
  load_http_failure load_http_failure: String,
  save_http_failure save_http_failure: String,
) -> CompletionPolicy(fields, response) {
  Required(to_fields, load_http_failure, save_http_failure)
}

pub fn optional(
  to_fields to_fields: fn(response) -> fields,
  missing missing: MissingConfig(fields),
  load_http_failure load_http_failure: String,
  save_http_failure save_http_failure: String,
) -> CompletionPolicy(fields, response) {
  Optional(to_fields, missing, load_http_failure, save_http_failure)
}

pub fn update(
  model: section.FormModel(fields),
  event: Event(response),
  policy: CompletionPolicy(fields, response),
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  case event, policy {
    LoadCompleted(generation, response),
      Required(to_fields, load_http_failure, _)
    -> complete_load(model, generation, response, to_fields, load_http_failure)
    LoadCompleted(generation, response),
      Optional(to_fields, missing, load_http_failure, _)
    ->
      complete_optional_load(
        model,
        generation,
        response,
        to_fields,
        missing,
        load_http_failure,
      )
    SaveCompleted(generation, response),
      Required(to_fields, _, save_http_failure)
    | SaveCompleted(generation, response),
      Optional(to_fields, _, _, save_http_failure)
    -> complete_save(model, generation, response, to_fields, save_http_failure)
  }
}

pub fn ensure_loaded(
  model: section.FormModel(fields),
  request: fn(Generation(section.LoadStream)) -> admin_effect.Command(msg),
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  case model.load_state {
    section.NotLoaded -> {
      let #(model, generation) = section.begin_load(model)
      #(model, request(generation))
    }
    section.Loading | section.Ready | section.LoadError(_) -> #(
      model,
      admin_effect.none(),
    )
  }
}

pub fn begin_save(
  model: section.FormModel(fields),
  request: request,
  save: fn(request, Generation(section.SaveStream)) -> admin_effect.Command(msg),
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  let #(model, generation) = section.begin_save(model)
  #(model, save(request, generation))
}

pub fn begin_validated_save(
  model: section.FormModel(fields),
  validation: Result(request, String),
  save: fn(request, Generation(section.SaveStream)) -> admin_effect.Command(msg),
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  case validation {
    Ok(request) -> begin_save(model, request, save)
    Error(message) -> #(
      section.validation_failed(model, message),
      admin_effect.none(),
    )
  }
}

fn complete_load(
  model: section.FormModel(fields),
  generation: Generation(section.LoadStream),
  response: api_response.Response(response),
  to_fields: fn(response) -> fields,
  http_failure_message: String,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  case response {
    api_response.Success(response) ->
      loaded(model, generation, to_fields(response))
    api_response.ApiFailure(error) ->
      load_failed(model, generation, api_response.error_message(error))
    api_response.HttpFailure(_) ->
      load_failed(model, generation, http_failure_message)
  }
}

fn complete_optional_load(
  model: section.FormModel(fields),
  generation: Generation(section.LoadStream),
  response: api_response.Response(response),
  to_fields: fn(response) -> fields,
  missing: MissingConfig(fields),
  http_failure_message: String,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  case response {
    api_response.ApiFailure(error) if error.code == missing.code ->
      loaded(model, generation, missing.fields)
    _ ->
      complete_load(
        model,
        generation,
        response,
        to_fields,
        http_failure_message,
      )
  }
}

fn complete_save(
  model: section.FormModel(fields),
  generation: Generation(section.SaveStream),
  response: api_response.Response(response),
  to_fields: fn(response) -> fields,
  http_failure_message: String,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  case response {
    api_response.Success(response) ->
      saved(model, generation, to_fields(response))
    api_response.ApiFailure(error) ->
      save_failed(model, generation, api_response.error_message(error))
    api_response.HttpFailure(_) ->
      save_failed(model, generation, http_failure_message)
  }
}

fn loaded(
  model: section.FormModel(fields),
  generation: Generation(section.LoadStream),
  fields: fields,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  #(
    section.resolve(model, section.loaded(model, generation, fields)),
    admin_effect.none(),
  )
}

fn load_failed(
  model: section.FormModel(fields),
  generation: Generation(section.LoadStream),
  message: String,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  #(
    section.resolve(model, section.load_failed(model, generation, message)),
    admin_effect.none(),
  )
}

fn saved(
  model: section.FormModel(fields),
  generation: Generation(section.SaveStream),
  fields: fields,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  #(
    section.resolve(model, section.saved(model, generation, fields)),
    admin_effect.none(),
  )
}

fn save_failed(
  model: section.FormModel(fields),
  generation: Generation(section.SaveStream),
  message: String,
) -> #(section.FormModel(fields), admin_effect.Command(msg)) {
  #(
    section.resolve(model, section.save_failed(model, generation, message)),
    admin_effect.none(),
  )
}
