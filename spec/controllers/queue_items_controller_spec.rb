require "rails_helper"

describe QueueItemsController do
	describe "GET index" do
		it "sets the @queue_items to the queue items of the logged in user" do
			abby = Fabricate(:user)
			session[:user_id] = abby.id
			queue_item1 = Fabricate(:queue_item, user: abby)
			queue_item2 = Fabricate(:queue_item, user: abby)
			get :index
			expect(assigns(:queue_items)).to match_array([queue_item1, queue_item2])
		end
		it "redirects to the sign in page for unathenticated users" do
			get :index
			expect(response).to redirect_to sign_in_path
		end
	end

	describe "POST create" do
		it 'redirects to my queue page' do
			session[:user_id] = Fabricate(:user).id
			video = Fabricate(:video)
			post :create, video_id: video.id
			expect(response).to redirect_to my_queue_path
		end

		it 'creates a queue item' do
			session[:user_id] = Fabricate(:user).id
			video = Fabricate(:video)
			post :create, video_id: video.id
			expect(QueueItem.count).to eq(1)
		end

		it 'creates a queue item associated with the video' do
			session[:user_id] = Fabricate(:user).id
			video = Fabricate(:video)
			post :create, video_id: video.id
			expect(QueueItem.first.video).to eq(video)
		end
		it 'creates a queue time associated with the current user' do
			abby = Fabricate(:user)
			session[:user_id] = abby.id
			video = Fabricate(:video)
			post :create, video_id: video.id
			expect(QueueItem.first.user).to eq(abby)
		end
		it 'puts the video as the last one in the queue' do
			abby = Fabricate(:user)
			session[:user_id] = abby.id
			vikings = Fabricate(:video)
			Fabricate(:queue_item, video: vikings, user: abby)
			stargate = Fabricate(:video)
			post :create, video_id: stargate.id
			stargate_queue_item = QueueItem.where(video_id: stargate.id, user_id: abby.id).first
			expect(stargate_queue_item.position).to eq(2)
		end
		it 'does not add video if it is already in the queue' do
			abby = Fabricate(:user)
			session[:user_id] = abby.id
			vikings = Fabricate(:video)
			Fabricate(:queue_item, video: vikings, user: abby)
			post :create, video_id: vikings.id
			expect(abby.queue_items.count).to eq(1)
		end
		it 'redirects to the sign in page for an unathenticated user' do
			post :create, video_id: 3
			expect(response).to redirect_to sign_in_path
		end
	end

	describe "DELETE destroy" do
		it 'redirects to the queue page' do
			session[:user_id] = Fabricate(:user).id
			queue_item = Fabricate(:queue_item)
			delete :destroy, id: queue_item.id
			expect(response).to redirect_to my_queue_path
		end		
		it 'deletes the queue item' do
			abby = Fabricate(:user)
			session[:user_id] = abby.id
			queue_item = Fabricate(:queue_item, user: abby)
			delete :destroy, id: queue_item.id
			expect(QueueItem.count).to eq(0)
		end
		it 'does not delete the queue item if it does not belong to the current user' do
			abby = Fabricate(:user)
			seth = Fabricate(:user)
			session[:user_id] = abby.id
			queue_item = Fabricate(:queue_item, user: seth)
			delete :destroy, id: queue_item.id
			expect(QueueItem.count).to eq(1)
		end
		it 'redirects to the sign in page for unauthenticated users' do
			delete :destroy, id: 3
			expect(response).to redirect_to sign_in_path
		end
	end

	describe "POST update_queue" do
		context 'with valid inputs'
			it 'redirects to the my queue page' do
				abby = Fabricate(:user)
				session[:user_id] = abby.id
				queue_item1 = Fabricate(:queue_item, user: abby, position: 1)
				queue_item2 = Fabricate(:queue_item, user: abby, position: 2)
				post :update_queue, queue_items: [{id: queue_item1.id, position: 2}, {id: queue_item2.id, position: 1}] 
				expect(response).to redirect_to my_queue_path
			end
			it 'reorders the queue items' do
				abby = Fabricate(:user)
				session[:user_id] = abby.id
				queue_item1 = Fabricate(:queue_item, user: abby, position: 1)
				queue_item2 = Fabricate(:queue_item, user: abby, position: 2)
				post :update_queue, queue_items: [{id: queue_item1.id, position: 2}, {id: queue_item2.id, position: 1}] 
				expect(abby.queue_items).to eq([queue_item2, queue_item1])
			end

			it 'normalizes the position numbers of the queue items' do
				abby = Fabricate(:user)
				session[:user_id] = abby.id
				queue_item1 = Fabricate(:queue_item, user: abby, position: 1)
				queue_item2 = Fabricate(:queue_item, user: abby, position: 2)
				post :update_queue, queue_items: [{id: queue_item1.id, position: 3}, {id: queue_item2.id, position: 1}] 
				expect(abby.queue_items.map(&:position)).to eq([1, 2])
			end
		context 'with invalid inputs'
		context 'with unauthenticated users'
		context 'with queue items that do not belong to current user'
	end
end