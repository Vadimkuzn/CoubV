require 'v_coub_lib'

class Likes::Coub::LikesController < ApplicationController

#--------------------------------------------------------------------------
  def index
   # список заданий для выполнения на лайки
   @coub_like_tasks = CoubLikeTask.where(paused: false, suspended: false).where.not(user_id: current_user.id)
#   @coub_like_tasks = CoubLikeTask.where(paused: false, suspended: false))
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
=begin
   @coub_like_task = current_user.coub_like_tasks.build(task_params)
   vclib = VCoubLib.new(current_user)
   coubjson = vclib.get_coub(@coub_like_task[:url])
   web = coubjson["file_versions"]["web"]
   template = web["template"]
   types = web["types"]
   versions = web["versions"]
   template.gsub!(/%{version}/, versions[0])
   template.gsub!(/%{type}/, types[0])
#   render plain: template.inspect
   @coub_like_task[:picture_path] = template
=end

   @coub_like_task = current_user.coub_like_tasks.build(task_params)
   vclib = VCoubLib.new(current_user)
   coubjson = vclib.get_coub(@coub_like_task[:url])
   web = coubjson["first_frame_versions"]
   template = web["template"]
   versions = web["versions"]
   template.gsub!(/%{version}/, versions[0])
#render plain: template.inspect
   @coub_like_task[:picture_path] = template


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


#{"template"=>"http://storage.akamai.coub.com/get/b118/p/coub/simple/cw_file/1ac600a5433/9e88520fce52b812775d3/%{type}_%{version}_size_1457374269_%{version}.%{type}", "types"=>["mp4"], "versions"=>["big", "med"]}
