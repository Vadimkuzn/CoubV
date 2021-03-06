window.App ||= {}

window.App.hide_task = (task_id) ->
  $('#task-' + task_id).effect('fade')

window.App.open_likes_coub_task_window = (task_id) ->
  open_coub_window("/likes/coub/tasks/#{task_id}/open", task_id)
  window.App.hide_task(task_id)

open_coub_window = (url, task_id) ->
  task_window = window.open(url, 'coub_task_window', 'width=900, height=600, top=' + ((screen.height - 600) / 2) + ',left=' + ((screen.width - 900) / 2) + ', resizable=yes, scrollbars=yes, status=yes');

  checker = () -> if task_window.closed
    clearInterval(closetimer)
    window.App.check_coub_task(task_id)

  closetimer = setInterval(checker, 100);

window.App.check_coub_task = (task_id) ->
  $.post("/likes/coub/tasks/#{task_id}/check", { id: task_id })
