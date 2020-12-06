# == Schema Information
#
# Table name: videos
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  title              :text
#  youtube_id         :string
#  leader_id          :bigint
#  follower_id        :bigint
#  description        :string
#  channel            :string
#  channel_id         :string
#  duration           :integer
#  upload_date        :date
#  view_count         :integer
#  avg_rating         :integer
#  tags               :string
#  song_id            :bigint
#  youtube_song       :string
#  youtube_artist     :string
#  performance_date   :datetime
#  performance_number :integer
#  performance_total  :integer
#  videotype_id       :bigint
#  event_id           :bigint
#

class Video < ApplicationRecord
  include Houndify

  require 'openssl'
  require 'base64'
  require 'net/http/post/multipart'
  require 'irb'
  require 'json'
  require 'securerandom'
  require 'houndify'

  # validates :leader, presence: true
  # validates :follower, presence: true
  # validates :song, presence: true
  # validates :artist, presence: true
  # validates :youtube_id, presence: true, uniqueness: true
  # validates :title, presence: true

  belongs_to :leader, required: false
  belongs_to :follower, required: false
  belongs_to :song, required: false
  belongs_to :videotype, required: false
  belongs_to :event, required: false

  scope :genre, ->(genre) { joins(:song).where(songs: { genre: genre }) }
  scope :videotype, ->(videotype) { joins(:videotype).where(videotypes: { name: videotype }) }
  scope :leader, ->(leader) { joins(:leader).where(leaders: { name: leader }) }
  scope :follower, ->(follower) { joins(:follower).where(followers: { name: follower }) }
  scope :event, ->(event) { joins(:event).where(events: { name: event }) }
  scope :channel, ->(channel) { where(channel: channel) }

  scope :paginate, lambda { |page, per_page|
    offset(per_page * page).limit(per_page)
  }

  class << self
    def search(query)
      if query
        where('leaders.name ILIKE :query or
                followers.name ILIKE :query or
                songs.genre ILIKE :query or
                songs.title ILIKE :query or
                songs.artist ILIKE :query or
                videotypes.name ILIKE :query',
              query: "%#{query.downcase}%")
      else
        all
      end
    end

    def import_channel(channel_id, limit)
      channel = Yt::Channel.new(id: channel_id)
      channel.videos.take(limit).each do |video|
        youtube_video = Yt::Video.new(id: video.id)

        # clip_audio(youtube_id)
        # grep_dancers(youtube_id)
        # acr_sound_match(file_name)
        # parse_acr_response(ask_acr_output)

        video_output = Video.new(
          youtube_id: video.id,
          title: video.title,
          description: youtube_video.description,
          upload_date: video.published_at,
          channel: video.channel_title,
          duration: video.length,
          channel_id: video.channel_id,
          view_count: video.view_count,
          tags: video.tags
        )
        video_output.save
      end
      # make sure it has follower & leader
      # get the song data
    end

    def grep_dancers(youtube_id)
      video = Video.find_by(youtube_id: youtube_id)

      # Attempt to parse title for leader and follower
      Leader.all.each do |leader|
        Video.where(leader_id: nil).where('levenshtein(unaccent(title), unaccent(?) ) < 4 ', leader.name).each do |video|
          video.leader = leader
          video.save
        end
      end

      Follower.all.each do |follower|
        Video.where(follower_id: nil).where('levenshtein(unaccent(title), unaccent(?) ) < 4', follower.name).each do |video|
          video.follower = follower
          video.save
        end
      end

      # Attempt to parse description for leader and follower
      Leader.all.each do |leader|
        Video.where(leader_id: nil).where('levenshtein(unaccent(description), unaccent(?) ) < 4 ', leader.name).each do |video|
          video.leader = leader
          video.save
        end
      end

      Follower.all.each do |follower|
        Video.where(follower_id: nil).where('levenshtein(unaccent(description), unaccent(?) ) < 4', follower.name).each do |video|
          video.follower = follower
          video.save
        end
      end
    end

    # Generates audio clip
    def clip_audio(_youtube_id)
      youtube_video = Video.find(youtube_id: video_id)
      youtube_audio_full = YoutubeDL.download(
        "https://www.youtube.com/watch?v=#{youtube_video.youtube_id}",
        { format: '140', output: '~/environment/data/audio/%(id)s.wav' }
      )

      song = FFMPEG::Movie.new(youtube_audio_full.filename.to_s)

      time_1 = youtube_audio_full.duration / 2
      time_2 = time_1 + 20

      output_file_path = youtube_audio_full.filename.gsub(/.wav/, "_#{time_1}_#{time_2}.wav")

      song_transcoded = song.transcode(output_file_path,
                                       { audio_codec: 'pcm_s16le',
                                         audio_channels: 1,
                                         audio_bitrate: 16,
                                         audio_sample_rate: 16_000,
                                         custom: %W[-ss #{time_1} -to #{time_2}] })
    end

    def parse_acr_response
      video = JSON.parse(ask_acr_output).extend Hashie::Extensions::DeepFind

      if video['status']['code'] == 0 | 2004 && video.deep_find('spotify').present?

        spotify_album_id = video.deep_find('spotify')['album']['id'] if video.deep_find('spotify')['album'].present?
        if video.deep_find('spotify')['album']['id'].present?
          spotify_album_name = RSpotify::Album.find(spotify_album_id).name
        end
        if video.deep_find('spotify')['artists'][0].present?
          spotify_artist_id = video.deep_find('spotify')['artists'][0]['id']
        end
        if video.deep_find('spotify')['artists'][0].present?
          spotify_artist_name = RSpotify::Artist.find(spotify_artist_id).name
        end
        if video.deep_find('spotify')['artists'][1].present?
          spotify_artist_id_2 = video.deep_find('spotify')['artists'][1]['id']
        end
        if video.deep_find('spotify')['artists'][2].present?
          spotify_artist_id_3 = video.deep_find('spotify')['artists'][2]['id']
        end
        if video.deep_find('spotify')['artists'][1].present?
          spotify_artist_name_2 = RSpotify::Artist.find(spotify_artist_id_2).name
        end
        if video.deep_find('spotify')['track']['id'].present?
          spotify_track_id = video.deep_find('spotify')['track']['id']
        end
        if video.deep_find('spotify')['track']['id'].present?
          spotify_track_name = RSpotify::Track.find(spotify_track_id).name
        end
        youtube_song_id = video.deep_find('youtube')['vid'] if video.deep_find('youtube').present?
        isrc = video.deep_find('external_ids')['isrc'] if video.deep_find('external_ids')['isrc'].present?

        youtube_video.update(
          spotify_album_id: spotify_album_id,
          spotify_album_name: spotify_album_name,
          spotify_artist_id: spotify_artist_id,
          spotify_artist_name: spotify_artist_name,
          spotify_artist_id_2: spotify_artist_id_2,
          spotify_artist_name_2: spotify_artist_name_2,
          spotify_track_id: spotify_track_id,
          spotify_track_name: spotify_track_name,
          youtube_song_id: youtube_song_id,
          isrc: isrc,
          acr_response_code: video['status']['code']
        )

      elsif video['status']['code'] == 0 && video.deep_find('external_ids')['isrc'].present?
        youtube_video.update(
          acr_response_code: video['status']['code'],
          isrc: video.deep_find('external_ids')['isrc']
        )

      else
        youtube_video.update(
          acr_response_code: video['status']['code']
        )
      end
    rescue Terrapin::ExitStatusError
    rescue RestClient::Exceptions::OpenTimeout
    rescue FFMPEG::Error
    rescue Errno::ENOENT
    end

    def acr_sound_match(file_name)
      requrl = 'http://identify-eu-west-1.acrcloud.com/v1/identify'
      access_key = ENV['ACRCLOUD_ACCESS_KEY']
      access_secret = ENV['ACRCLOUD_SECRET_KEY']

      http_method = 'POST'
      http_uri = '/v1/identify'
      data_type = 'audio'
      signature_version = '1'
      timestamp = Time.now.utc.to_i.to_s

      string_to_sign = http_method + "\n" + http_uri + "\n" + access_key + "\n" + data_type + "\n" + signature_version + "\n" + timestamp

      digest = OpenSSL::Digest.new('sha1')
      signature = Base64.encode64(OpenSSL::HMAC.digest(digest, access_secret, string_to_sign))

      sample_bytes = File.size(file_name)

      url = URI.parse(requrl)
      File.open(file_name) do |file|
        req = Net::HTTP::Post::Multipart.new url.path,
                                             'sample' => UploadIO.new(file, 'audio/mp3', file_name),
                                             'access_key' => access_key,
                                             'data_type' => data_type,
                                             'signature_version' => signature_version,
                                             'signature' => signature,
                                             'sample_bytes' => sample_bytes,
                                             'timestamp' => timestamp
        res = Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
        body = res.body.force_encoding('utf-8')
        body
      end
    end

    # To fetch video, run this from the console:
    # Video.parse_json('data/030tango_channel_data_json')
    # Video.parse_json('/Users/justin/desktop/environment/data/channel_json')
    # def parse_json(file_path)
    #   json_file = Dir.glob("#{file_path}/**/*.json").map
    #   json_file.each do |youtube_video|
    #     video = JSON.parse(File.read(youtube_video))
    #     video = Video.new(
    #       youtube_id: video['id'],
    #       title: video['title'],
    #       description: video['description'],
    #       youtube_song: video['track'],
    #       youtube_artist: video['artist'],
    #       upload_date: video['upload_date'],
    #       channel: video['uploader'],
    #       duration: video['duration'],
    #       channel_id: video['uploader_id'],
    #       view_count: video['view_count'],
    #       avg_rating: video['average_rating'],
    #       tags: video['tags']
    #     )
    #     # video.grep_title
    #     video.save
    #   end
    # end

    # To fetch video, run this from the console:
    # Video.for_channel('UCtdgMR0bmogczrZNpPaO66Q')
    # def for_channel(url)
    #   channel = Yt::Channel.new url: url
    #   channel.videos.each do |youtube_video|
    #     video = Video.new(
    #       youtube_id: video['id'],
    #       title: video['title'],
    #       description: video['description'],
    #       upload_date: video['upload_date'],
    #       channel: video['uploader'],
    #       duration: video['duration'],
    #       channel_id: video['uploader_id'],
    #       view_count: video['view_count'],
    #       avg_rating: video['average_rating'],
    #       tags: video['tags']
    #     )
    #     video.save
    #   end
    # end

    # def import_video(_youtube_id)
    #   video = Yt::Video.new id.to_s
    #   video = Video.new(
    #     youtube_id: video.id,
    #     title: video.title,
    #     description: youtube_video.description,
    #     upload_date: video.publishedAt,
    #     channel: video.channelTitle,
    #     duration: video.length,
    #     channel_id: video.channelId,
    #     view_count: video.view_count,
    #     tags: video.tags
    #   )
    #   video.save
    # end

    # To fetch specific snippet from video, run this in the console:

    #  Video.youtube_trim("5HfJ_n3wvLw","00:02:40.00", "00:02:55.00")
    def youtube_trim(youtube_id, time_1, time_2)
      youtube_video = YoutubeDL.download(
        "https://www.youtube.com/watch?v=#{youtube_id}",
        { format: 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
          output: '~/downloads/youtube/%(title)s-%(id)s.%(ext)s' }
      )
      video = FFMPEG::Movie.new(youtube_video.filename.to_s)
      timestamp = time_1.to_s.split(':')
      timestamp_2 = time_2.to_s.split(':')
      output_file_path = youtube_video.filename.gsub(/.mp4/, "_trimmed_#{timestamp[1]}_#{timestamp[2]}_to_#{timestamp_2[1]}_#{timestamp_2[2]}.mp4")
      video_transcoded = video.transcode(output_file_path, custom: %W[-ss #{time_1} -to #{time_2}])
    end
  end
end
