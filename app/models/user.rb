class User < ActiveRecord::Base
  validates_presence_of :email, :password, :full_name
  validates_uniqueness_of :email

  has_secure_password
 
  has_many :queue_items, -> { order(position: :asc) }

  def normalize_queue_item_position
  	queue_items.each_with_index do |queue_item, index|
			queue_item.update_attributes(position: index+1)
		end
  end
end