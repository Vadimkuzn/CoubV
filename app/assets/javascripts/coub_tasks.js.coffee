window.App ||= {}

window.App.open_coub_task_window = (task_id, user_id) ->
  open_coub_window("likes/coub/tasks/#{task_id}/open", task_id, user_id)
  window.App.hide_task(task_id)

open_coub_window = (url, task_id, user_id) ->
  task_window = window.open(url, 'coub_task_window', 'width=900, height=600, top=' + ((screen.height - 600) / 2) + ',left=' + ((screen.width - 900) / 2) + ', resizable=yes, scrollbars=yes, status=yes');

  checker = () -> if task_window.closed
    clearInterval(closetimer)
    window.App.check_coub_task(task_id, user_id)

  closetimer = setInterval(checker, 100);

window.App.check_coub_task = (task_id, user_id) ->
  $.post("/coub/tasks/#{task_id}/check", { id: task_id, user_id: user_id })
