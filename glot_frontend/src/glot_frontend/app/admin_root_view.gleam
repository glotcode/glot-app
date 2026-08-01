import glot_frontend/admin/router_state
import glot_frontend/admin/router_view
import glot_frontend/admin/ui/breadcrumbs
import glot_frontend/app/admin_root_managed
import glot_frontend/app/public_quick_actions
import glot_frontend/app/quick_actions_managed
import glot_frontend/app/runtime
import glot_web/page/site_chrome
import glot_web/page/top_bar
import lustre/element.{type Element}

pub fn view(
  model: admin_root_managed.Model,
) -> Element(admin_root_managed.Msg) {
  case runtime.is_admin(model.lifecycle.runtime.session) {
    True -> admin_view(model)
    False -> element.none()
  }
}

fn admin_view(
  model: admin_root_managed.Model,
) -> Element(admin_root_managed.Msg) {
  let presented_route = admin_root_managed.presented_route(model)
  let page_content =
    router_view.view(
      router_state.page(admin_root_managed.presented_page(model)),
      model.lifecycle.runtime.now,
    )
    |> element.map(fn(msg) {
      admin_root_managed.AdminPageMsg(presented_route, msg)
    })

  let content = case breadcrumbs.is_admin_route(presented_route) {
    True -> breadcrumbs.wrap(presented_route, page_content)
    False -> page_content
  }

  site_chrome.view(
    top_bar_model: top_bar_model(model),
    footer_account_route: runtime.current_user_route(
      model.lifecycle.runtime.session,
    ),
    content:,
  )
}

fn top_bar_model(
  model: admin_root_managed.Model,
) -> top_bar.ViewModel(admin_root_managed.Msg) {
  public_quick_actions.view_model(
    model.lifecycle.runtime.session,
    model.quick_actions,
    admin_root_managed.quick_action_sections(model),
    public_quick_actions.Messages(
      open: admin_root_managed.QuickActionsMsg(quick_actions_managed.Opened),
      close: admin_root_managed.QuickActionsMsg(quick_actions_managed.Dismissed),
      query_changed: fn(query) {
        admin_root_managed.QuickActionsMsg(quick_actions_managed.QueryChanged(
          query,
        ))
      },
      key_pressed: fn(key) {
        admin_root_managed.QuickActionsMsg(quick_actions_managed.KeyPressed(key))
      },
      submitted: admin_root_managed.QuickActionsMsg(
        quick_actions_managed.Submitted,
      ),
    ),
    admin_root_managed.QuickActionSelected,
  )
}
