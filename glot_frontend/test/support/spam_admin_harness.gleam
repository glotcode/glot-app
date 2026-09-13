import glot_frontend/admin/command
import glot_frontend/admin/config/spam_classifier
import glot_frontend/admin/config/spam_classifier_view
import glot_frontend/admin/interpreter
import glot_frontend/admin/production_ports
import glot_frontend/admin/snippets/detail_managed
import glot_frontend/admin/snippets/detail_view
import lustre
import lustre/element
import lustre/element/html

type Model {
  Model(config: spam_classifier.Model, detail: detail_managed.Model)
}

type Msg {
  Config(spam_classifier.Msg)
  Detail(detail_managed.Msg)
}

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let #(config, config_command) =
    spam_classifier.ensure_loaded(spam_classifier.init())
  let #(detail, _) = detail_managed.init("fixture-snippet")
  let #(detail, detail_command) = detail_managed.ensure_loaded(detail)
  #(
    Model(config, detail),
    interpreter.run(
      command.batch([
        command.map(config_command, Config),
        command.map(detail_command, Detail),
      ]),
      production_ports.new(),
    ),
  )
}

fn update(model: Model, msg: Msg) {
  case msg {
    Config(msg) -> {
      let #(config, next) = spam_classifier.update(model.config, msg)
      #(
        Model(..model, config: config),
        interpreter.run(command.map(next, Config), production_ports.new()),
      )
    }
    Detail(msg) -> {
      let #(detail, next) = detail_managed.update(model.detail, msg)
      #(
        Model(..model, detail: detail),
        interpreter.run(command.map(next, Detail), production_ports.new()),
      )
    }
  }
}

fn view(model: Model) {
  html.div([], [
    element.map(spam_classifier_view.view(model.config), Config),
    element.map(detail_view.view(model.detail), Detail),
  ])
}
