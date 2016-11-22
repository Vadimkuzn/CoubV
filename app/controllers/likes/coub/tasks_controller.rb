require 'v_coub_lib'

class Likes::Coub::TasksController < ApplicationController
#--------------------------------------------------------------------------
  def index
   if current_user
    @coub_tasks = current_user.coub_tasks
   end
  end
#--------------------------------------------------------------------------
  def new
   @coub_task = CoubTask.new
  end
#--------------------------------------------------------------------------

=begin
t.integer   "user_id",
t.string    "title",
t.string    "type",
t.string    "url",
t.integer   "cost",
t.string    "item_id",
t.string    "shortcode",
t.boolean   "deleted",
t.boolean   "paused",
t.boolean   "suspended",
t.boolean   "verified",
t.integer   "current_count",
t.integer   "max_count",
t.integer   "members_count",
t.string    "picture_path",
t.boolean   "finished",
t.datetime  "created_at",
t.datetime  "updated_at",

 t.id                                                      #
 t.integer   "user_id",       null:    false               # кто поставил задание. на данном этапе забей на это поле !!!
 t.string    "title",         limit:   255                 # название задания, необязательное, больше для юзера
 t.string    "type",          limit:   255, null: false    # тип задания(сейчас это будет только 1 тип: CbLikeTask - накрутка лайков к записи) !!!
 t.string    "url",           limit:   255, null: false    # адрес, куда будут накручиваться лайки. например: https://coub.com/view/bfrkm !!!
 t.integer   "cost",          null:    false               # стоимость в баллах за одно выполнение задания. !!!
 t.string    "item_id",       limit:   255, null: false    # внутренний идентификатор записи на сайте coub. их внутренний id !!!
 t.string    "shortcode",     limit:   255                 # короткое имя записи, для ссылки https://coub.com/view/bfrkm это будет bfrkm !!!
 t.boolean   "deleted",       default: false, null: false  # удалено задание или нет
 t.boolean   "paused",        default: false, null: false  # задание на паузе или нет(юзер может сам ставить и снимать с паузы)
 t.boolean   "suspended",     default: false, null: false  # задание заморожено или нет
 t.boolean   "verified",      default: false, null: false  # на будущее
 t.integer   "current_count", null:    false               # количество баллов на балансе аккаунта !!!
 t.integer   "max_count",     null:    false               # !!!
 t.integer   "members_count", null:    false               # !!!
 t.string    "picture_path",  limit:   255                 # url картинки, которая будет отображаться при выполнении задания
 t.boolean   "finished",      default: false, null: false  # задание завершено(выполнено) или нет
 t.datetime  "created_at",    null:    false               # !!!
 t.datetime  "updated_at",    null:    false               # !!!
=end

#--------------------------------------------------------------------------
  def destroy
   @coub_task = CoubTask.find(params[:id])
#   @coub_task.deleted = true
#   current_user.money += @coub_task.current_count
#   @coub_task.current_count = 0
#   @coub_task.save!
#   current_user.save!
#   redirect_to likes_coub_tasks_path

    begin
      task = Tasks::Destroyer.destroy(params[:id], current_user.id, CoubTask)
      current_user.reload

      respond_to do |format|
        format.html do
#          if task.verified?
#            redirect_to real_coub_tasks_path
#          else
#            redirect_to likes_coub_tasks_path
#          end
          redirect_to likes_coub_tasks_path
        end
        format.js
#        format.json { render json: {deleted: true, money: current_user.money, reals: current_user.reals } }
        format.json { render json: {deleted: true, money: current_user.money } }
      end
=begin
    rescue RecordNotFound
      flash[:error] = 'Task not found'
#      redirect_to dashboard_path
      redirect_to likes_coub_tasks_path
=end
    end

  end
#--------------------------------------------------------------------------
  def delete_all
   current_user.coub_tasks.each do |t|
    t.deleted = true
    current_user.money += t.current_count
    t.current_count = 0
    t.save!
   end
   current_user.save!
   redirect_to likes_coub_tasks_path
  end
#--------------------------------------------------------------------------
  def pause
   @coub_task = CoubTask.find(params[:task_id])
   @coub_task.paused ? @coub_task.paused = false : @coub_task.paused = true
   @coub_task.save!
   redirect_to likes_coub_tasks_path
  end
#--------------------------------------------------------------------------
  def open
    @coub_task = CoubTask.not_suspended.not_paused.not_finished.find(params[:task_id])
#    @coub_task = CoubTask.find(params[:task_id])
    if @coub_task
      CoubTasksUser.create(:coub_task => @coub_task, :user => current_user)
      redirect_to @coub_task.redirect_url
    end
  end
#--------------------------------------------------------------------------
  def check
    @coub_task = CoubTask.find(params[:task_id])
    vclib = VCoubLib.new(current_user)
    @completed = vclib.task_completed?(@coub_task)

    if @completed
#"VCompleted? Here I am #{@completed} #{@coub_task[:url]}\r\n".append_file("c:\\check.txt")
#"@coub_task finished? #{@coub_task[:finished].to_s}\r\n".append_file("c:\\check.txt")
    	begin
      @coub_task = CoubTask.find(params[:task_id])
      CoubTasksUser.create!(:user => current_user, :coub_task => @coub_task)
     rescue => ex
      logger.error "Exception in check coub task: #{ex.inspect}"
     end

     CoubTask.transaction do
      current_user.lock!
      @coub_task.add_money_to_user(current_user)
     end
     current_user.save!
    else
     @coub_task.decrease_limit_counter
     @coub_task.save!
    end

    rescue => ex
     if ex.message == "Sorry, this coub has been deleted."
      task = CoubTask.find(params[:id])
      task.suspend!
      task.save!
      @completed = false
     end

  end
#--------------------------------------------------------------------------
private
  def task_params
   params.require(:coub_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished, :created_at, :updated_at)
  end
#--------------------------------------------------------------------------
end
