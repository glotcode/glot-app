import glot_frontend/public/home/message.{type Msg}
import glot_frontend/public/home/model.{type Model}
import glot_web/page/home
import lustre/element.{type Element}

pub fn view(_model: Model) -> Element(Msg) {
  home.view(load_ad: True)
}
