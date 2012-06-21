require "api_spec_helper"

describe "User" do
  before do
    @user = Factory(:user, :mobile => "+55 (81) 9194-5317",
                    :localization => "Recife", :birth_localization => "Recife")
    @application, @current_user, @token = generate_token(@user)
  end

  context "when GET /user/:id" do
    before do
      get "/api/users/#{@user.id}", :oauth_token => @token, :format => 'json'
    end

    it "should return status 200 (ok)" do
      response.code.should == "200"
    end

    it "should have login, id, links, email, first_name, last_name, " + \
       " birthday, friends_count, mobile, localization, birth_localization" do

      %w(login id links email first_name last_name birthday friends_count mobile localization birth_localization).each do |attr|
        parse(response.body).should have_key attr
      end
    end

    %w(self enrollments statuses timeline contacts).each do |rel|
      it "should link to #{rel}" do
        link = href_to(rel, parse(response.body))

        get link, :oauth_token => @token, :format => 'json'
        response.code.should == '200'
      end
    end
  end

  context "when GET /me" do
    it "should show current_user info" do
      get "/api/me", :oauth_token => @token, :format => 'json'

      parse(response.body)['id'].should == @current_user.id
    end
  end

  context "when listing users" do
    before do
      @environment = Factory(:complete_environment, :owner => @current_user)
      @course = @environment.courses.first
      @space = @course.spaces.first

      @members = 3.times.collect do
        user = Factory(:user)
        @course.join(user)
        user
      end
      @members << @course.owner
    end

    context "on course" do
      it_should_behave_like "user listing" do # spec/support/api/user_listing...
        let(:subject) { @course }
        let(:token) { @token }
        let(:members) { @members }
        let(:entity_name) { "#{subject.class.to_s.tableize}" }
      end
    end

    context "on space" do
      it_should_behave_like "user listing" do # spec/support/api/user_listing...
        let(:subject) { @space }
        let(:token) { @token }
        let(:members) { @members }
        let(:entity_name) { "#{subject.class.to_s.tableize}" }
      end
    end

    context "on environment" do
      it_should_behave_like "user listing" do # spec/support/api/user_listing...
        let(:subject) { @environment }
        let(:token) { @token }
        let(:members) { @members }
        let(:entity_name) { "#{subject.class.to_s.tableize}" }
      end
    end
  end

  context "when listing contacts" do
    let(:friend) { Factory(:user) }
    before do
      @current_user.be_friends_with(friend)
      friend.be_friends_with(@current_user)
    end

    it "should return the correct number of contacts" do
      get "/api/users/#{@current_user.id}/contacts", :oauth_token => @token,
        :format => 'json'

      parse(response.body).length.should == 1
    end
  end

  context "when GET /space/:space_id/users to a non-existent space" do
    it "should return code 404 (not existent)" do
      get "/api/spaces/2198219/users", :oauth_token => @token,
        :format => 'json'

      response.code.should == '404'
    end
  end


  context "when GET /space/:space_id/user to a non-existent space" do
    it "should return code 404 (not existent)" do
      get "/api/courses/2198219/users", :oauth_token => @token,
        :format => 'json'

      response.code.should == '404'
    end
  end
end