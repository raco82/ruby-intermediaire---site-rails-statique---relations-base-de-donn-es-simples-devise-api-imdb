require 'themoviedb'
require 'dotenv'
class MoviesController < ApplicationController
  before_action :set_movie, only: %i[show new create edit update destroy]
  before_action :authenticate_user!, except: %i[index show search]
  # GET /movies
  # GET /movies.json

  Tmdb::Api.key((ENV['TMDB_API_KEY']).to_s)

  def index
    # @movies = Movie.all.order('title').paginate(page: params[:page], per_page: 4)
    if params[:filter] == 'popular'
      @movies = Tmdb::Movie.popular
      @headline = 'Films populaires'
    elsif params[:filter] == 'toprated'
      @movies = Tmdb::Movie.top_rated
      @headline = 'Films les mieux notés'
    elsif params[:filter] == 'nowplaying'
      @movies = Tmdb::Movie.now_playing
      @headline = 'Films en salle en ce moment'
    elsif params[:filter] == 'upcoming'
      @movies = Tmdb::Movie.upcoming
      @headline = 'Bientôt dans vos salles'
    else
      @movies = Tmdb::Movie.popular
      @headline = 'Flims les plus populaires'
    end

    if params[:order] == 'title'
      @movies.sort! { |a, b| a.title <=> b.title }
      @subheadline = 'par Titre'
    elsif params[:order] == 'release'
      @movies.sort! { |a, b| a.release_date <=> b.release_date }
      @subheadline = 'par Date de sortie'
    elsif params[:order] == 'genre'
      @movies.sort! { |a, b| a.genres <=> b.genres }
      @subheadline = 'par Genre'
    else
      @movies.sort! { |a, b| a.title <=> b.title }
    end
  end

  def search
    @movies = if params[:search].present?
                Tmdb::Movie.find(params[:search])
              else
                Tmdb::Movie.popular
              end

    if params[:order] == 'title'
      @movies.sort! { |a, b| a.title <=> b.title }
      @subheadline = 'by Title'
    elsif params[:order] == 'release'
      @movies.sort! { |a, b| a.release_date <=> b.release_date }
      @subheadline = 'by Release Date'
    elsif params[:order] == 'genre'
      @movies.sort! { |a, b| a.genres <=> b.genres }
      @subheadline = 'by Genre'
    else
      @movies.sort! { |a, b| a.title <=> b.title }
    end
  end

  # GET /movies/1
  # GET /movies/1.json
  def show
    @reviews = Review.where(movie_id: @movie['id']).order('created_at DESC')
    @avg_review = if @reviews.blank?
                    0
                  else
                    @reviews.average(:rating).round(2)
                  end
  end

  # GET /movies/new
  def new
    @movie = current_user.movies.build
  end

  # GET /movies/1/edit
  def edit; end

  # POST /movies
  # POST /movies.json
  def create
    @movie = current_user.movies.build(movie_params)

    respond_to do |format|
      if @movie.save
        format.html { redirect_to @movie, notice: 'Movie was successfully created.' }
        format.json { render :show, status: :created, location: @movie }
      else
        format.html { render :new }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movies/1
  # PATCH/PUT /movies/1.json
  def update
    respond_to do |format|
      if @movie.update(movie_params)
        format.html { redirect_to movies_url, notice: 'Movie was successfully updated.' }
        format.json { render :show, status: :ok, location: @movie }
      else
        format.html { render :edit }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movies/1
  # DELETE /movies/1.json
  def destroy
    @movie.destroy
    respond_to do |format|
      format.html { redirect_to movies_url, notice: 'Movie was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_movie
    @movie = Tmdb::Movie.detail(params[:id])
    @movie_id = @movie['id']
    @movie_poster = "https://image.tmdb.org/t/p/w185/#{@movie['poster_path']}"
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def movie_params
    params.require(:movie).permit(:title, :release_date, :genre, :rating, :image)
  end
end
