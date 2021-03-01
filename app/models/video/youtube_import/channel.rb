class Video::YoutubeImport::Channel
  class << self
    def import(channel_id)
      new(channel_id).import
    end

    def import_videos(channel_id)
      new(channel_id).import_videos
    end
  end

  def initialize(channel_id)
    @youtube_channel = fetch_by_id(channel_id)
    @channel = channel
  end

  def import
    @channel = Channel.create(to_channel_params)
  end

  def import_videos
    new_videos.each do |youtube_id|
      ImportVideoWorker.perform_async(youtube_id)
    end
  end

  private

  def fetch_by_id(channel_id)
    Yt::Channel.new id: channel_id
  end

  def to_channel_params
    base_params.merge(count_params)
  end

  def base_params
    {
      channel_id:    @youtube_channel.id,
      title:         @youtube_channel.title,
      thumbnail_url: @youtube_channel.thumbnail_url
    }
  end

  def count_params
    {
      total_videos_count: @youtube_channel.video_count
    }
  end

  def get_channel_video_ids(channel_id)
    `youtube-dl https://www.youtube.com/channel/#{channel_id}/videos  --get-id --skip-download`.split
  end

  def youtube_channel_videos
    @youtube_channel.video_count >= 500 ? get_channel_video_ids(channel_id) : @youtube_channel.videos.map(&:id)
  end

  def channel
    Channel.find_by(channel_id: @youtube_channel.id)
  end

  def channel_videos
    @channel.videos.map(&:youtube_id).to_a
  end

  def new_videos
    youtube_channel_videos - channel_videos
  end
end