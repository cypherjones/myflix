require "rails_helper"

describe QueueItemsController do
  describe "GET index" do
    it "sets the @queue_items to the queue items of the logged in user" do
      abby = Fabricate(:user)
      set_current_user(abby)
      queue_item1 = Fabricate(:queue_item, user: abby)
      queue_item2 = Fabricate(:queue_item, user: abby)
      get :index
      expect(assigns(:queue_items)).to match_array([queue_item1, queue_item2])
    end

    it_behaves_like "requires sign in" do
      let(:action) { get :index }
    end
  end

  describe "POST create" do
    it 'redirects to my queue page' do
      set_current_user
      video = Fabricate(:video)
      post :create, video_id: video.id
      expect(response).to redirect_to my_queue_path
    end

    it 'creates a queue item' do
      set_current_user
      video = Fabricate(:video)
      post :create, video_id: video.id
      expect(QueueItem.count).to eq(1)
    end

    it 'creates a queue item associated with the video' do
      set_current_user
      video = Fabricate(:video)
      post :create, video_id: video.id
      expect(QueueItem.first.video).to eq(video)
    end
    it 'creates a queue time associated with the current user' do
      abby = Fabricate(:user)
      set_current_user(abby)
      video = Fabricate(:video)
      post :create, video_id: video.id
      expect(QueueItem.first.user).to eq(abby)
    end
    it 'puts the video as the last one in the queue' do
      abby = Fabricate(:user)
      set_current_user(abby)
      vikings = Fabricate(:video)
      Fabricate(:queue_item, video: vikings, user: abby)
      stargate = Fabricate(:video)
      post :create, video_id: stargate.id
      stargate_queue_item = QueueItem.where(video_id: stargate.id, user_id: abby.id).first
      expect(stargate_queue_item.position).to eq(2)
    end
    it 'does not add video if it is already in the queue' do
      abby = Fabricate(:user)
      set_current_user(abby)
      vikings = Fabricate(:video)
      Fabricate(:queue_item, video: vikings, user: abby)
      post :create, video_id: vikings.id
      expect(abby.queue_items.count).to eq(1)
    end
 
    it_behaves_like "requires sign in" do
      let(:action) { post :create, video_id: 3 }
    end
  end

  describe "DELETE destroy" do
    it 'redirects to the queue page' do
      set_current_user
      queue_item = Fabricate(:queue_item)
      delete :destroy, id: queue_item.id
      expect(response).to redirect_to my_queue_path
    end   
    it 'deletes the queue item' do
      abby = Fabricate(:user)
      set_current_user(abby)
      queue_item = Fabricate(:queue_item, user: abby)
      delete :destroy, id: queue_item.id
      expect(QueueItem.count).to eq(0)
    end
    it 'does not delete the queue item if it does not belong to the current user' do
      abby = Fabricate(:user)
      seth = Fabricate(:user)
      set_current_user(abby)
      queue_item = Fabricate(:queue_item, user: seth)
      delete :destroy, id: queue_item.id
      expect(QueueItem.count).to eq(1)
    end
  
    it_behaves_like "requires sign in" do
      let(:action) { delete :destroy, id: 3 }
    end

    it 'normalizes queue items after destroy' do
      abby = Fabricate(:user)
      set_current_user(abby)
      queue_item1 = Fabricate(:queue_item, user: abby, position: 1)
      queue_item2 = Fabricate(:queue_item, user: abby, position: 2)
      delete :destroy, id: queue_item1.id
      expect(QueueItem.first.position).to eq(1)
    end
  end

  describe "POST update_queue" do
    context 'with valid inputs' do

      let(:abby) { Fabricate(:user) }
      let(:video) { Fabricate(:video) }
      let(:queue_item1) { Fabricate(:queue_item, user: abby, position: 1, video: video) }
      let(:queue_item2) { Fabricate(:queue_item, user: abby, position: 2, video: video) }

      before do
        session[:user_id] = abby.id
      end

      it 'redirects to the my queue page' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 2}, {id: queue_item2.id, position: 1}] 
        expect(response).to redirect_to my_queue_path
      end

      it 'reorders the queue items' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 2}, {id: queue_item2.id, position: 1}] 
        expect(abby.queue_items).to eq([queue_item2, queue_item1])
      end

      it 'normalizes the position numbers of the queue items' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 3}, {id: queue_item2.id, position: 1}] 
        expect(abby.queue_items.map(&:position)).to eq([1, 2])
      end
    end

    context 'with invalid inputs' do
      let(:abby) { Fabricate(:user) }
      let(:video) { Fabricate(:video) }
      let(:queue_item1) { Fabricate(:queue_item, user: abby, position: 1, video: video) }
      let(:queue_item2) { Fabricate(:queue_item, user: abby, position: 2, video: video) }

      before do
        set_current_user(abby)
      end

      it 'redirects to the my queue page' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 3}, {id: queue_item2.id, position: 1}] 
        expect(response).to redirect_to my_queue_path
      end
      it 'sets the flash error message' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 3.4}, {id: queue_item2.id, position: 1}] 
        expect(flash[:danger]).to be_present
      end
      it 'does not change the queue' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 3}, {id: queue_item2.id, position: 2.1}] 
        expect(queue_item1.reload.position).to eq(1) 
      end
    end

    context 'with unauthenticated users' do
      it_behaves_like "requires sign in" do
        let(:action) { post :update_queue, queue_items: [{id: 2, position: 3}, {id: 3, position: 2}] }
      end
    end

    context 'with queue items that do not belong to current user' do
      it 'does not change the queue item' do
        abby = Fabricate(:user)
        set_current_user(abby)
        seth = Fabricate(:user)
        video = Fabricate(:video)
        queue_item1 = Fabricate(:queue_item, user: seth, position: 1, video: video)
        queue_item2 = Fabricate(:queue_item, user: abby, position: 2, video: video)
        post :update_queue, queue_items: [{id: queue_item1.id, position: 3}, {id: queue_item2.id, position: 2}] 
        expect(queue_item1.reload.position).to eq(1) 
      end
    end
  end
end