require 'my_coub_lib'

class Likes::Coub::LikesController < ApplicationController
#--------------------------------------------------------------------------
  def index
   # список заданий для выполнения на лайки
   if current_user
    @coub_tasks = current_user.coub_tasks
   end
  end
#--------------------------------------------------------------------------
  def new
   @coub_like_task = CoubLikeTask.new
  end
#--------------------------------------------------------------------------
  def edit
   @coub_like_task = CoubLikeTask.find(params[:id])
  end
#--------------------------------------------------------------------------
  def show
   @coub_like_task = CoubLikeTask.find(params[:id])
  end
#--------------------------------------------------------------------------
  def create
   #@coub_task = current_user.coub_like_tasks.build(task_params)
   @coub_like_task = current_user.coub_like_tasks.build(task_params)

#render plain: params[:coub_like_task].inspect
#render plain: @coub_like_task.inspect

   #@coub_task[:type] = coub_like_task[:type]     #temporary
   @coub_like_task[:picture_path] = "fff"     #temporary
   @coub_like_task[:user_id] = current_user[:id]
#render plain: current_user.inspect
   if @coub_like_task.save
#render plain: @coub_like_task.inspect
#    result = MyCoubLib.new.does_like?(current_user)
#    render plain: result.inspect

# does_like?(item_id, access_token)
    redirect_to likes_coub_tasks_path
#    redirect_to [:likes, @coub_task]
#    redirect_to likes_coub_likes_path
   else
    render 'new'
   end
  end
#--------------------------------------------------------------------------
  def update
   @coub_like_task = CoubLikeTask.find(params[:id])
   if @coub_like_task.update(task_params)
#    redirect_to [:likes, @coub_like_task]
    redirect_to likes_coub_tasks_path
   else
    render 'edit'
   end
  end
#--------------------------------------------------------------------------
private
 def task_params
  params.require(:coub_like_task).permit(:user_id, :title, :type, :url, :cost, :item_id, :shortcode, :deleted, :paused, :suspended, :verified, :current_count, :max_count, :members_count, :picture_path, :finished)
 end
#--------------------------------------------------------------------------
end
