require "http/client"
require "json"

module SlackCry
  class Upload
    alias HttpPostProc = Proc(String, HTTP::Headers, IO, HTTP::Client::Response)
    DEFAULT_HTTP_POST = ->(url : String, headers : HTTP::Headers, body : IO) : HTTP::Client::Response {
      HTTP::Client.post(url, headers: headers, body: body)
    }

    # Public: Upload using a channel ID
    def self.send_by_id(
      channel_id : String,
      file_path : String,
      filename : String = "file.zip",
      initial_comment : String? = nil,
      http_post : HttpPostProc = DEFAULT_HTTP_POST
    ) : HTTP::Client::Response
      _send(channel_id, file_path, filename, initial_comment, http_post)
    end

    # Public: Upload using a channel name
    def self.send_by_name(
      channel_name : String,
      file_path : String,
      filename : String = "file.zip",
      initial_comment : String? = nil,
      http_post : HttpPostProc = DEFAULT_HTTP_POST
    ) : HTTP::Client::Response
      channel_id = SlackCry.config.channels[channel_name]? ||
                   raise "❌ No channel ID mapped for name: #{channel_name}"
      _send(channel_id, file_path, filename, initial_comment, http_post)
    end

    private def self._send(
      channel_id : String,
      file_path : String,
      filename : String,
      initial_comment : String?,
      http_post : HttpPostProc
    ) : HTTP::Client::Response
      token = ENV["SLACKCRY_SLACK_BOT_TOKEN"]? ||
              raise "😬 Missing SLACKCRY_SLACK_BOT_TOKEN"

      file = ::File.open(file_path)
      form = HTTP::FormData.build do |f|
        f.field("channels", channel_id)
        f.file("file", file, filename: filename, content_type: "application/zip")
        f.field("initial_comment", initial_comment) if initial_comment
      end

      http_post.call(
        "https://slack.com/api/files.upload",
        HTTP::Headers{
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => form.content_type
        },
        form.body
      )
    end
  end
end
