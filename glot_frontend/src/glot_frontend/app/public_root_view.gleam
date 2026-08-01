import glot_frontend/app/public_page_view
import glot_frontend/app/public_quick_actions
import glot_frontend/app/public_root_managed
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/runtime
import glot_web/page/site_chrome
import glot_web/page/top_bar
import lustre/element.{type Element}

pub fn view(
  model: public_root_managed.Model,
) -> Element(public_root_managed.Msg) {
  let content =
    public_page_view.view(
      public_root_managed.presented_page(model),
      model.lifecycle.runtime.session,
      model.lifecycle.runtime.now,
    )
    |> element.map(public_root_managed.PageMsg)

  site_chrome.view(
    top_bar_model: top_bar_model(model),
    footer_account_route: runtime.current_user_route(
      model.lifecycle.runtime.session,
    ),
    content:,
  )
}

fn top_bar_model(
  model: public_root_managed.Model,
) -> top_bar.ViewModel(public_root_managed.Msg) {
  public_quick_actions.view_model(
    model.lifecycle.runtime.session,
    model.quick_actions,
    public_root_managed.quick_action_sections(model),
    public_quick_actions.Messages(
      open: public_root_managed.QuickActionsMsg(quick_actions_managed.Opened),
      close: public_root_managed.QuickActionsMsg(
        quick_actions_managed.Dismissed,
      ),
      query_changed: fn(query) {
        public_root_managed.QuickActionsMsg(quick_actions_managed.QueryChanged(
          query,
        ))
      },
      key_pressed: fn(key) {
        public_root_managed.QuickActionsMsg(quick_actions_managed.KeyPressed(
          key,
        ))
      },
      submitted: public_root_managed.QuickActionsMsg(
        quick_actions_managed.Submitted,
      ),
    ),
    public_root_managed.QuickActionSelected,
  )
}
