pub type ExecutorControl {
  ExecutorControl(interrupt_for_shutdown: fn() -> Result(Nil, String))
}
