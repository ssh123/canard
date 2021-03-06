require 'test_helper'
require 'canard'

describe Canard::UserModel do

  before do
    Canard.abilities_path = 'abilities'
  end

  # Sanity test
  it "must be an user" do
    user = User.new
    user.must_be_instance_of User
    user = UserWithoutRole.new
    user.must_be_instance_of UserWithoutRole
    user = UserWithoutRoleMask.new
    user.must_be_instance_of UserWithoutRoleMask
  end

  describe 'acts_as_user' do

    it 'adds role_model to the class' do
      User.included_modules.must_include RoleModel
      User.must_respond_to :roles
    end

    describe "on an ActiveRecord model" do

      describe 'with a role_mask' do

        describe 'and :roles => [] specified' do

          it 'sets the valid_roles for the class' do
            User.valid_roles.must_equal [:viewer, :author, :admin]
          end

        end

        describe 'and no :roles => [] specified' do

          it 'sets no roles' do
            UserWithoutRole.valid_roles.must_equal []
          end
        end

      end

      describe 'with no roles_mask' do

        it 'sets no roles' do
          UserWithoutRole.valid_roles.must_equal []
        end
      end

      describe "with no table" do
        
        subject { Class.new(ActiveRecord::Base) }

        it "sets no roles" do
          subject.class_eval { acts_as_user :roles => [:admin] }
          subject.valid_roles.must_equal []
        end
        
        it "does not raise any errors" do
          proc { subject.class_eval { acts_as_user :roles => [:admin] } }.must_be_silent
        end
        
        it "returns nil" do
          subject.class_eval { acts_as_user :roles => [:admin] }.must_be_nil
        end
      end
    end
    
    describe "on a regular Ruby class" do

      describe "with a roles_mask" do

        it "assigns the roles" do
          PlainRubyUser.valid_roles.must_equal [:viewer, :author, :admin]
        end
      end

      describe "with no roles_mask" do

        it "sets no roles" do
          PlainRubyNonUser.valid_roles.must_equal []
        end
      end
    end
  end

  describe "scopes" do

    describe "on an ActiveRecord model with roles" do

      before do
        @no_role             = User.create
        @admin_author_viewer = User.create(:roles => [:admin, :author, :viewer])
        @author_viewer       = User.create(:roles => [:author, :viewer])
        @viewer              = User.create(:roles => [:viewer])
        @admin_only          = User.create(:roles => [:admin])
        @author_only         = User.create(:roles => [:author])
      end

      after do
        User.delete_all
      end

      subject { User }

      it "adds a scope to return instances with each role" do
        subject.must_respond_to :admins
        subject.must_respond_to :authors
        subject.must_respond_to :viewers
      end

      it "adds a scope to return instances without each role" do
        subject.must_respond_to :non_admins
        subject.must_respond_to :non_authors
        subject.must_respond_to :non_viewers
      end

      describe "finding instances with a role" do

        describe "admins scope" do

          subject { User.admins.sort_by(&:id) }

          it "returns only admins" do
            subject.must_equal [@admin_author_viewer, @admin_only].sort_by(&:id)
          end

          it "doesn't return non admins" do
            subject.wont_include @no_role
            subject.wont_include @author_viewer
            subject.wont_include @author_only
            subject.wont_include @viewer
          end

        end

        describe "authors scope" do

          subject { User.authors.sort_by(&:id) }

          it "returns only authors" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @author_only].sort_by(&:id)
          end

          it "doesn't return non authors" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @viewer
          end

        end

        describe "viewers scope" do

          subject { User.viewers.sort_by(&:id) }

          it "returns only viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @viewer].sort_by(&:id)
          end

          it "doesn't return non authors" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @author_only
          end

        end

      end

      describe "finding instances without a role" do

        describe "non_admins scope" do

          subject { User.non_admins.sort_by(&:id) }

          it "returns only non_admins" do
            subject.must_equal [@no_role, @author_viewer, @viewer, @author_only].sort_by(&:id)
          end

          it "doesn't return admins" do
            subject.wont_include @admin_author_viewer
            subject.wont_include @admin_only
          end

        end

        describe "non_authors scope" do

          subject { User.non_authors.sort_by(&:id) }

          it "returns only non_authors" do
            subject.must_equal [@no_role, @viewer, @admin_only].sort_by(&:id)
          end

          it "doesn't return authors" do
            subject.wont_include @admin_author_viewer
            subject.wont_include @author_viewer
            subject.wont_include @author_only
          end

        end

        describe "non_viewers scope" do

          subject { User.non_viewers.sort_by(&:id) }

          it "returns only non_viewers" do
            subject.must_equal [@no_role, @admin_only, @author_only].sort_by(&:id)
          end

          it "doesn't return viewers" do
            subject.wont_include @admin_author_viewer
            subject.wont_include @author_viewer
            subject.wont_include @viewer
          end

        end

      end

      describe "with_any_role" do

        describe "specifying admin only" do

          subject { User.with_any_role(:admin).sort_by(&:id) }

          it "returns only admins" do
            subject.must_equal [@admin_author_viewer, @admin_only].sort_by(&:id)
          end

          it "doesn't return non admins" do
            subject.wont_include @no_role
            subject.wont_include @author_viewer
            subject.wont_include @author_only
            subject.wont_include @viewer
          end

        end

        describe "specifying author only" do

          subject { User.with_any_role(:author).sort_by(&:id) }

          it "returns only authors" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @author_only].sort_by(&:id)
          end

          it "doesn't return non authors" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @viewer
          end

        end

        describe "specifying viewer only" do

          subject { User.with_any_role(:viewer).sort_by(&:id) }

          it "returns only viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @viewer].sort_by(&:id)
          end

          it "doesn't return non authors" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @author_only
          end

        end

        describe "specifying admin and author" do

          subject { User.with_any_role(:admin, :author).sort_by(&:id) }

          it "returns only admins and authors" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @admin_only, @author_only].sort_by(&:id)
          end

          it "doesn't return non admins or authors" do
            subject.wont_include @no_role
            subject.wont_include @viewer
          end

        end

        describe "specifying admin and viewer" do

          subject { User.with_any_role(:admin, :viewer).sort_by(&:id) }

          it "returns only admins and viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @admin_only, @viewer].sort_by(&:id)
          end

          it "doesn't return non admins or viewers" do
            subject.wont_include @no_role
            subject.wont_include @author_only
          end

        end

        describe "specifying author and viewer" do

          subject { User.with_any_role(:author, :viewer).sort_by(&:id) }

          it "returns only authors and viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @author_only, @viewer].sort_by(&:id)
          end

          it "doesn't return non authors or viewers" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
          end

        end

        describe "specifying admin, author and viewer" do

          subject { User.with_any_role(:admin, :author, :viewer).sort_by(&:id) }

          it "returns only admins, authors and viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @admin_only, @author_only, @viewer].sort_by(&:id)
          end

          it "doesn't return non admins, authors or viewers" do
            subject.wont_include @no_role
          end

        end

      end

      describe "with_all_roles" do

        describe "specifying admin only" do

          subject { User.with_all_roles(:admin).sort_by(&:id) }

          it "returns only admins" do
            subject.must_equal [@admin_author_viewer, @admin_only].sort_by(&:id)
          end

          it "doesn't return non admins" do
            subject.wont_include @no_role
            subject.wont_include @author_viewer
            subject.wont_include @author_only
            subject.wont_include @viewer
          end

        end

        describe "specifying author only" do

          subject { User.with_all_roles(:author).sort_by(&:id) }

          it "returns only authors" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @author_only].sort_by(&:id)
          end

          it "doesn't return non authors" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @viewer
          end

        end

        describe "specifying viewer only" do

          subject { User.with_all_roles(:viewer).sort_by(&:id) }

          it "returns only viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer, @viewer].sort_by(&:id)
          end

          it "doesn't return non authors" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @author_only
          end

        end

        describe "specifying admin and author" do

          subject { User.with_all_roles(:admin, :author).sort_by(&:id) }

          it "returns only admins and authors" do
            subject.must_equal [@admin_author_viewer].sort_by(&:id)
          end

          it "doesn't return non admin and authors" do
            subject.wont_include @no_role
            subject.wont_include @author_viewer
            subject.wont_include @author_only
            subject.wont_include @admin_only
            subject.wont_include @viewer
          end

        end

        describe "specifying admin and viewer" do

          subject { User.with_all_roles(:admin, :viewer).sort_by(&:id) }

          it "returns only admins and viewers" do
            subject.must_equal [@admin_author_viewer].sort_by(&:id)
          end

          it "doesn't return non admins or viewers" do
            subject.wont_include @no_role
            subject.wont_include @author_viewer
            subject.wont_include @author_only
            subject.wont_include @admin_only
            subject.wont_include @viewer
          end

        end

        describe "specifying author and viewer" do

          subject { User.with_all_roles(:author, :viewer).sort_by(&:id) }

          it "returns only authors and viewers" do
            subject.must_equal [@admin_author_viewer, @author_viewer].sort_by(&:id)
          end

          it "doesn't return non authors or viewers" do
            subject.wont_include @no_role
            subject.wont_include @admin_only
            subject.wont_include @author_only
            subject.wont_include @viewer
          end

        end

        describe "specifying admin, author and viewer" do

          subject { User.with_all_roles(:admin, :author, :viewer).sort_by(&:id) }

          it "returns only admins, authors and viewers" do
            subject.must_equal [@admin_author_viewer].sort_by(&:id)
          end

          it "doesn't return non admins, authors or viewers" do
            subject.wont_include @no_role
            subject.wont_include @author_viewer
            subject.wont_include @author_only
            subject.wont_include @admin_only
            subject.wont_include @viewer
          end

        end

      end

    end

    describe "on a plain Ruby class" do

      subject { PlainRubyUser }

      it "creates no scope methods" do
        subject.wont_respond_to :admins
        subject.wont_respond_to :authors
        subject.wont_respond_to :viewers
        subject.wont_respond_to :non_admins
        subject.wont_respond_to :non_authors
        subject.wont_respond_to :non_viewers
        subject.wont_respond_to :with_any_role
        subject.wont_respond_to :with_all_roles
      end

    end

  end

end
