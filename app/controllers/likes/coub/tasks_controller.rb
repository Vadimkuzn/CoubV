require 'my_coub_lib'

class Likes::Coub::TasksController < ApplicationController
#--------------------------------------------------------------------------
  def index
   if current_user
    @coub_tasks = current_user.coub_tasks
   end
  end
#--------------------------------------------------------------------------
#  def show
#   @coub_task = CoubTask.find(params[:id])
#  end
#--------------------------------------------------------------------------
  def new
   @coub_task = CoubTask.new
  end
#--------------------------------------------------------------------------
#  def edit
#   @coub_task = CoubTask.find(params[:id])
#  end
#--------------------------------------------------------------------------
  def create
   @coub_task = current_user.coub_tasks.build(task_params)

   coub_like_task = current_user.coub_like_tasks.build(task_params)

#render plain: params[:coub_task].inspect
#render plain: @coub_task.inspect
   @coub_task[:type] = coub_like_task[:type]     #temporary
   @coub_task[:picture_path] = "fff"     #temporary

   if @coub_task.save
#render plain: @coub_task.inspect
#    result = MyCoubLib.new.does_like?(current_user)
#    render plain: result.inspect

# does_like?(item_id, access_token)
    redirect_to [:likes, @coub_task]
   else
    render 'new'
   end
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

 t.id                                                      # !!!
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
#  def update
#   @coub_task = CoubTask.find(params[:id])
#   if @coub_task.update(task_params)
#    redirect_to [:likes, @coub_task]
#   else
#    render 'edit'
#   end
#  end
#--------------------------------------------------------------------------
  def destroy
   @coub_task = CoubTask.find(params[:id])
   @coub_task.deleted = true
   @coub_task.save!
   redirect_to likes_coub_tasks_path
  end
#--------------------------------------------------------------------------
  def delete_all
   current_user.coub_tasks.each do |t|
    t.deleted = true
    t.save!
   end
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
private
  def task_params
   params.require(:coub_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished, :created_at, :updated_at)
  end
#--------------------------------------------------------------------------
end
