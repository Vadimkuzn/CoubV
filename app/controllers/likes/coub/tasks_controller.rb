class Likes::Coub::TasksController < ApplicationController
  def index
   @coub_tasks = CoubTask.all
  end

  def show
   @coub_task = CoubTask.find(params[:id])
  end

  def new
   @coub_task = CoubTask.new
  end

  def edit
   @coub_task = CoubTask.find(params[:id])
  end

  def create
#render plain: params[:coub_task].inspect
   @coub_task = CoubTask.new(task_params)
#   @coub_task[:id] = 33                 #Unique!!!
#   @coub_task[:id] = rand(2^31).to_s     #temporary
   @coub_task[:user_id] = 4              #temporary
#   @coub_task[:created_at] = Time.now    #temporary
#   @coub_task[:updated_at] = Time.now    #temporary
   @coub_task[:ctype] = :CbLikeTask
   @coub_task[:item_id] = 55             #temporary
   @coub_task[:shortcode] = "bfrkm"
   @coub_task[:current_count] = 8
   @coub_task[:picture_path] = "fff"

   if @coub_task.save
    redirect_to [:likes, @coub_task]
   else
    render 'new'
   end
  end

#render plain: @task.inspect

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

  def update
   @coub_task = CoubTask.find(params[:id])
   if @coub_task.update(task_params)
    redirect_to [:likes, @coub_task]
   else
    render 'edit'
   end
  end

  def destroy
   @coub_task = CoubTask.find(params[:id])
   @coub_task.destroy
   redirect_to likes_coub_tasks_path
  end

private
  def task_params
   params.require(:coub_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished, :created_at, :updated_at)
  end

end
