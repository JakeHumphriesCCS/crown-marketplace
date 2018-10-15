class SearchController < ApplicationController
  def nominated_worker_question
    @back_path = homepage_path
    @form_path = nominated_worker_answer_path
  end

  def nominated_worker_answer
    if params[:nominated_worker].present?
      if params[:nominated_worker] == 'yes'
        redirect_to school_postcode_question_path(nominated_worker: 'yes')
      else
        redirect_to non_nominated_worker_outcome_path(nominated_worker: 'no')
      end
    else
      redirect_to nominated_worker_question_path
    end
  end

  def school_postcode_question
    @back_path = nominated_worker_question_path(params.permit(:nominated_worker))
    @form_path = school_postcode_answer_path
  end

  def school_postcode_answer
    redirect_to branches_path(params.permit(:postcode, :nominated_worker))
  end

  def non_nominated_worker_outcome
    @back_path = nominated_worker_question_path(params.permit(:nominated_worker))
  end
end
