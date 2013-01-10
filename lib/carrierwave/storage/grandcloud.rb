# encoding: utf-8
require 'carrierwave'
require 'digest/hmac'
require 'digest/md5'
require "sndacs"

module CarrierWave
  module Storage
    class Grandcloud < Abstract
      class File

        def initialize(uploader, base, path)
          @uploader, @base, @path = uploader, base, path
        end

        ##
        # Returns the current path/filename of the file on Cloud Files.
        #
        # === Returns
        #
        # [String] A path
        #
        attr_reader :path

        attr_accessor :content_type

        ##
        # Reads the contents of the file from Cloud Files
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          object.content
        end

        ##
        # Remove the file from Cloud Files
        #
        def delete
          object.destroy rescue nil
        end

        def url(expires_at = Time.now + 3000)
          unless @uploader.grandcloud_bucket_private
            "http://#{Sndacs::Config.content_host % @uploader.grandcloud_location}/#{@uploader.grandcloud_bucket}/#{path}"
          else
            bucket.policy == 'Allow' ? object.url : object.temporary_url(expires_at)
          end
        end

        def store(data)
          @object = bucket.objects.build(@path)
          @object.content = data
          @object.save
        end
        
        ##
        # Lookup value for file content-type header
        #
        # === Returns
        #
        # [String] value of content-type
        #
        def content_type
          @content_type || object.content_type
        end

        private

        def headers
          @headers ||= {}
        end

        def bucket
          @bucket ||= begin
            Sndacs::Service.new(
              :access_key_id     => @uploader.grandcloud_access_id,
              :secret_access_key => @uploader.grandcloud_access_key
            ).bucket(@uploader.grandcloud_bucket, @uploader.grandcloud_location)
          end
        end

        def object
          @object ||= bucket.objects.find(@path)
        end

      end #// End of File

      def store!(file)
        f = CarrierWave::Storage::Grandcloud::File.new(uploader, self, uploader.store_path)
        f.store(file.read)
        f
      end

      def retrieve!(identifier)
        CarrierWave::Storage::Grandcloud::File.new(uploader, self, uploader.store_path(identifier))
      end

    end
  end
end
