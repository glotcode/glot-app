import glot_core/admin/job_dto
import glot_core/admin/periodic_job_dto
import glot_frontend/admin/local_datetime.{type LocalDateTime, type ParseResult}
import glot_frontend/admin/periodic_jobs/model.{
  type JobStream, type RecentJobsStream, type SaveStream,
}
import glot_frontend/api/response as api_response
import glot_frontend/request_generation.{type Generation}

pub type Msg {
  PeriodicJobLoaded(
    Generation(JobStream),
    api_response.Response(periodic_job_dto.GetPeriodicJobResponse),
  )
  LoadedPeriodicJobFormatted(
    Generation(JobStream),
    periodic_job_dto.PeriodicJobResponse,
    LocalDateTime,
  )
  PayloadChanged(String)
  IntervalSecondsChanged(String)
  EnabledToggled
  NextRunDateChanged(String)
  NextRunTimeChanged(String)
  ResetClicked
  SaveClicked
  NextRunAtParsed(Generation(SaveStream), ParseResult)
  SaveFinished(
    Generation(SaveStream),
    api_response.Response(periodic_job_dto.UpdatePeriodicJobResponse),
  )
  SavedPeriodicJobFormatted(
    Generation(SaveStream),
    periodic_job_dto.PeriodicJobResponse,
    LocalDateTime,
  )
  RecentJobsLoaded(
    Generation(RecentJobsStream),
    api_response.Response(job_dto.ListJobsResponse),
  )
}
