import gleam/option
import glot_backend/email/effect/template/algebra as email_template_algebra
import glot_backend/email/model/template as email_template
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types

pub fn list_email_templates() -> program_types.Program(
  List(email_template.EmailTemplate),
) {
  program.perform_db(
    program_types.EmailTemplateEffect(email_template_algebra.ListEmailTemplates(
      next: program.succeed,
    )),
  )
}

pub fn get_email_template_by_name(
  name: email_template.EmailTemplateName,
) -> program_types.Program(option.Option(email_template.EmailTemplate)) {
  program.perform_db(
    program_types.EmailTemplateEffect(
      email_template_algebra.GetEmailTemplateByName(
        name: name,
        next: program.succeed,
      ),
    ),
  )
}

pub fn update_email_template(
  template: email_template.EmailTemplate,
) -> program_types.Program(Nil) {
  program.perform_db(
    program_types.EmailTemplateEffect(
      email_template_algebra.UpdateEmailTemplate(
        template: template,
        next: program.succeed,
      ),
    ),
  )
}
