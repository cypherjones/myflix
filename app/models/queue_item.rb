class QueueItem < ActiveRecord::Base
	belongs_to :user
	belongs_to :video

	delegate :category, to: :video 
	delegate :title, to: :video, prefix: :video

	validates_numericality_of :position, {only_integer: true}

	def rating
		review = Review.where(video_id: video_id, user_id: user_id).first
		review.rating if review
	end

	def rating=(new_rating)
		review = Review.where(video_id: video_id, user_id: user_id).first
		review.update_column(:rating, new_rating)
	end

	def category_name
		category.name
	end

end