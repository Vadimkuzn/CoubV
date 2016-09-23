#require 'v_coub_lib'

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
 t.integer   "user_id",       null:    false               # ��� �������� �������. �� ������ ����� ����� �� ��� ���� !!!
 t.string    "title",         limit:   255                 # �������� �������, ��������������, ������ ��� �����
 t.string    "type",          limit:   255, null: false    # ��� �������(������ ��� ����� ������ 1 ���: CbLikeTask - �������� ������ � ������) !!!
 t.string    "url",           limit:   255, null: false    # �����, ���� ����� ������������� �����. ��������: https://coub.com/view/bfrkm !!!
 t.integer   "cost",          null:    false               # ��������� � ������ �� ���� ���������� �������. !!!
 t.string    "item_id",       limit:   255, null: false    # ���������� ������������� ������ �� ����� coub. �� ���������� id !!!
 t.string    "shortcode",     limit:   255                 # �������� ��� ������, ��� ������ https://coub.com/view/bfrkm ��� ����� bfrkm !!!
 t.boolean   "deleted",       default: false, null: false  # ������� ������� ��� ���
 t.boolean   "paused",        default: false, null: false  # ������� �� ����� ��� ���(���� ����� ��� ������� � ������� � �����)
 t.boolean   "suspended",     default: false, null: false  # ������� ���������� ��� ���
 t.boolean   "verified",      default: false, null: false  # �� �������
 t.integer   "current_count", null:    false               # ���������� ������ �� ������� �������� !!!
 t.integer   "max_count",     null:    false               # !!!
 t.integer   "members_count", null:    false               # !!!
 t.string    "picture_path",  limit:   255                 # url ��������, ������� ����� ������������ ��� ���������� �������
 t.boolean   "finished",      default: false, null: false  # ������� ���������(���������) ��� ���
 t.datetime  "created_at",    null:    false               # !!!
 t.datetime  "updated_at",    null:    false               # !!!
=end

#--------------------------------------------------------------------------
  def destroy
   @coub_task = CoubTask.find(params[:id])
   @coub_task.deleted = true
   current_user.money += @coub_task.current_count
   @coub_task.current_count = 0
   @coub_task.save!
   current_user.save!
   redirect_to likes_coub_tasks_path
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
#    @task = CoubTask.not_suspended.not_paused.not_finished.find(params[:id])
    @task = CoubTask.find(params[:task_id])

    if @task
      CoubTasksUser.create(:coub_task => @task, :user => current_user)
      redirect_to @task.redirect_url
    end
  end
#--------------------------------------------------------------------------
  def check
    @task = CoubTask.find(params[:id])
    @completed = @task.task_completed?(current_user)

    if @completed
      CoubTask.transaction do
        current_user.lock!
        @task.add_money_to_user(current_user)
      end
    else
      @task.decrease_limit_counter
    end
  rescue IncorrectTokenException
    @incorrect_token = true
  rescue => ex
    if ex.message == "Sorry, this coub has been deleted."
      task = CoubTask.find(params[:id])
      task.suspend!
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
