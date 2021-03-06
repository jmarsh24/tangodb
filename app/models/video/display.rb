class Video::Display
  def initialize(video)
    @video = video
  end

  def display
    @display ||= Video::Display.new(self)
  end

  def any_song_attributes
    el_recodo_attributes || spotify_attributes || youtube_attributes || acr_cloud_attributes
  end

  def external_song_attributes
    spotify_attributes || youtube_attributes || acr_cloud_attributes
  end

  def el_recodo_attributes
    return if @video.song.blank?

    "#{@video.song.title.titleize} - #{@video.song.artist.titleize} - #{@video.song.genre.titleize}"
  end

  def spotify_attributes
    return if @video.spotify_track_name.blank? || @video.spotify_artist_name.blank?

    "#{@video.spotify_track_name.titleize} - #{@video.spotify_artist_name.titleize}"
  end

  def youtube_attributes
    return if @video.youtube_song.blank? || @video.youtube_artist.blank?

    "#{@video.youtube_song.titleize} - #{@video.youtube_artist.titleize}"
  end

  def acr_cloud_attributes
    return if @video.acr_cloud_track_name.blank? || @video.acr_cloud_artist_name.blank?

    "#{@video.acr_cloud_track_name.titleize} - #{@video.acr_cloud_artist_name.titleize}"
  end

  def dancer_names
    return if @video.leader.blank? || @video.follower.blank?

    "#{@video.leader.name.titleize} & #{@video.follower.name.titleize}"
  end
end
