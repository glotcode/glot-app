import glot_core/admin/run_log_dto
import glot_core/loadable
import youid/uuid

pub type Model {
  Model(id: uuid.Uuid, log: loadable.Loadable(run_log_dto.RunLogDetailResponse))
}

pub fn is_presentable(model: Model) -> Bool {
  loadable.is_terminal(model.log)
}
