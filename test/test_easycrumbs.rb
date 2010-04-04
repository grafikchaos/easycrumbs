require 'helper'

class TestEasycrumbs < Test::Unit::TestCase
  context "EasyCrumbs tests" do
    setup do
      @usa = Country.create(:name => "USA", :breadcrumb => "United States of America")
      @titanic = @usa.movies.create(:name => "Titanic")
      @leo = @titanic.actors.create(:first_name => "Leonardo", :last_name => "Di Caprio")
    end

    context "Models testing" do
      should "Leo play in  Titanic" do
        assert_equal(@titanic, @leo.movie)
      end 
    
      should "Titanic be produced in Usa" do
        assert_equal(@usa, @titanic.country)
      end 
    end
    
    context "Breadcrumb model" do
      context "set object" do
        should "model object be ok" do
          assert_equal(@usa, Breadcrumb.new(@usa).object)
        end
        
        should "controller object be ok" do
          @controller = MoviesController.new
          assert_equal(@controller, Breadcrumb.new(@controller).object)
        end
        
        should "raise exception for String object" do
          assert_raise(InvalidObject) { Breadcrumb.new("Some string") }
        end
      end
      
      context "set name" do
        context "for model" do
          should "return breadcrumb column by default" do
            assert_equal("United States of America", Breadcrumb.new(@usa).name)
          end
          
          should "return name column if someone set it" do
            assert_equal(@titanic.name, Breadcrumb.new(@titanic, :name_column => "name").name)
          end
          
          should "return specyfic name using breadcrumb method" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo).name)
          end
          
          should "raise exception if can not find name" do
            assert_raise(NoName) {  Breadcrumb.new(@leo, :name_column => "wrong_column")}
          end
        end
        
        context "for controller" do
          should "return controller name" do
            assert_equal("Movies", Breadcrumb.new(MoviesController.new).name)
          end
          
          should "return breadcrumb method from controller" do
            assert_equal("Countries list", Breadcrumb.new(CountriesController.new).name)
          end
        end
        
        context "with prefix option" do
          should "return name with prefix if action is passed by parameter and it is one of defaults(new or edit)" do
            assert_equal("Edit Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "edit").name)
          end
          
          should "return only name if it is set to :none" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "edit", :prefix => :none).name)
          end
        
          should "return prefix and name for every action if it is set to :every" do
            assert_equal("Show Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "show", :prefix => :every).name)
          end
        
          should "return prefix and name if action is in prefix array" do
            assert_equal("Destroy Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "destroy", :prefix => [:destroy, :edit]).name)
          end
        
          should "return only name if action is not in prefix array" do
            assert_equal("Leonardo Di Caprio", Breadcrumb.new(@leo, :action => "show", :prefix => [:destroy, :edit]).name)
          end
        end
        
        context "with i18n enable" do
          should "return transalted name for controller" do
            I18n.expects(:t).with("breadcrumbs.controllers.movies").returns("la movies")
            assert_equal("la movies", Breadcrumb.new(MoviesController.new, :i18n => true).name)
          end
          
          should "return transalted action as a prefix" do
            I18n.expects(:t).with("breadcrumbs.actions.edit").returns("Editzione")
            assert_equal("Editzione Leonardo Di Caprio", Breadcrumb.new(@leo, :i18n => true, :action => "edit").name)
          end
        end
        
        context "set path" do
          should "return path if it exist" do
            assert_equal("/countries/1/movies/1/actors/1", Breadcrumb.new(@leo, :path => {:country_id => "1", :movie_id => "1", :id => "1", :action => "show", :controller => "actors"}).path)
          end
          
          should "raise RoutingError when can not find path" do
            assert_raise(EasyCrumbs::NoPath) { Breadcrumb.new(@leo, :path => {:country_id => "1", :movie_id => "1", :id => "1", :action => "no_action", :controller => "actors"}) }
          end
          
          should "retrun nil when can not find path and blank_links is on" do
            assert_equal(nil, Breadcrumb.new(@leo, :path => {:country_id => "1", :movie_id => "1", :id => "1", :action => "no_action", :controller => "actors"}, :blank_links => true).path)
          end
          
          should "return root path for empty path" do
            assert_equal("/", Breadcrumb.new(@leo, :path => {}).path)
          end
        end
      end
    end
  
    context "Collection" do
      context "finding route" do
        setup do
          @collection = Collection.new
          @collection.stubs(:path => "/countries/1/movies/1/actors/1", :method => :get)
        end
        
        should "return route if it can find it" do
          assert_equal(ActionController::Routing::Route, @collection.find_route.class)
        end
        
        should "raise error when it can not find route" do
          assert_raise(EasyCrumbs::NotRecognized) do
            @collection.stubs(:path => "/countres/1/videos/1")
            @collection.find_route
          end
        end
      end
      
      context "selecting right segments" do
        should "select only static and dynamic segments" do
          results = Collection.new.segments(ActionController::Routing::Routes.routes[0])
          results = results.map(&:class).uniq
          results.delete(ActionController::Routing::StaticSegment)
          results.delete(ActionController::Routing::DynamicSegment)
          assert_equal(true, results.empty?)
        end
      end
    end
  
    context "View Helpers" do
    end
  end
end
