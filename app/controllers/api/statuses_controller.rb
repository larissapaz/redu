module Api
  class StatusesController < Api::ApiController

    def show
      status = Status.find(params[:id])
      authorize! :read, status

      respond_with(:api, status)
    end

    def create
      status = Status.new(params[:status]) do |s|
        s.statusable = context(params)
        s.user = current_user
        s.type = params[:status].fetch(:type, 'Activity').camelize
      end

      authorize! :read, status.statusable

      # Transformando numa instancia do filho do sti
      status = status.becomes(status.type.constantize)
      if status.save
        respond_with(:api, status, :location => api_status_url(status))
      else
        respond_with(:api, status)
      end
    end

    def index
      context = context(params)
      authorize! :read, context
      statuses = statuses(context)

      statuses = case params[:type]
      when 'help'
        statuses.where(:type => 'Help')
      when 'log'
        statuses.where(:type => 'Log')
      when 'activity'
        statuses.where(:type => 'Activity')
      else
        statuses.where(:type => ['Help', 'Activity'])
      end

      statuses = statuses.page(params[:page])

      respond_with(:api, statuses)
    end

    def destroy
      status = Status.find(params[:id])
      authorize! :manage, status

      status.destroy

      respond_with(:api, status)
    end

    def timeline
      statusable = context(params)
      authorize! :read, statusable

      statuses = if statusable.is_a?(Space)
        Status.from_hierarchy(statusable)
      else
        statusable.overview
      end

      statuses = statuses.page(params[:page])

      respond_with(:api, statuses.not_compound_log)
    end

    protected

    def context(params)
      if params[:space_id]
        Space.find(params[:space_id])
      elsif params[:lecture_id]
        Lecture.find(params[:lecture_id])
      else
        User.find(params[:user_id])
      end
    end

    def statuses(context)
      statuses = if context.is_a? User
        Status.where(:user_id => context)
      else
        Status.where(:statusable_id => context,
                     :statusable_type => context.class.to_s)
      end
      statuses.not_compound_log
    end
  end
end