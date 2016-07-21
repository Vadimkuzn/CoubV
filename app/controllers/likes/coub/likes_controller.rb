require 'v_coub_lib'

class Likes::Coub::LikesController < ApplicationController

#--------------------------------------------------------------------------
  def index
   # список заданий для выполнения на лайки
   @coub_like_tasks = CoubLikeTask.where.not(paused: true, suspended: true, user_id: current_user.id)
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
   @coub_like_task = current_user.coub_like_tasks.build(task_params)
   vclib = VCoubLib.new(current_user)
   @coub_like_task[:picture_path] = vclib.get_current_user_avatar()
   if @coub_like_task.save
    redirect_to likes_coub_tasks_path
   else
    render 'new'
   end
  end
#--------------------------------------------------------------------------
  def update
   @coub_like_task = CoubLikeTask.find(params[:id])
   if @coub_like_task.update(task_params)
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
