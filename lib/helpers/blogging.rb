module Nanoc3::Helpers::Blogging

	def prepare_feed(params)		
		# Extract parameters		
		@item[:limit] ||= 10
		@item[:articles] = params[:articles] || latest_articles(10) || []
		@item[:content_proc] = params[:content_proc] || lambda { |a| a.reps[0].content_at_snapshot(:pre)}
		@item[:excerpt_proc] = params[:excerpt_proc] || lambda { |a| a[:excerpt] }
		@item[:author_uri] ||= @site.config[:base_url]
		@item[:author_name] ||= @site.config[:author_name]
		raise RuntimeError.new('Cannot build feed: site configuration has no base_url') 	if @site.config[:base_url].nil?
		raise RuntimeError.new('Cannot build feed: feed item has no title') if @item[:title].nil?
		raise RuntimeError.new('Cannot build feed: no articles') if @item[:articles].empty?
		raise RuntimeError.new('Cannot build feed: one or more articles doesn\'t have a date') if @item[:articles].any? { |a| a[:date].nil? }
		@item[:last] = @item[:articles].first
	end

	def rss_feed(params={})
		return
		require 'builder'
		require 'time'
		prepare_feed params
		# Create builder
		buffer = ''
		xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)
		# Build feed
		xml.instruct!
		xml.rss(:version => '2.0') do
			xml.channel do
				xml.title @item[:title]
				xml.language 'en-us'
				xml.lastBuildDate @item[:last][:date].rfc822
				xml.ttl '40'
				xml.link @site.config[:base_url]
				xml.description
				@item[:articles].each do |a|
					xml.item do
						xml.title a[:title]
						xml.description @item[:content_proc].call(a)
						xml.pubDate a[:date].rfc822
						xml.guid url_for(a)
						xml.link url_for(a)
						xml.author @site.config[:author_email]
						xml.comments url_for(a)+'#comments'
						[*a[:tags]].each do |t|
							xml.category t
						end
					end
				end
			end
			buffer
		end
	end

	# Redefine atom_feed method
	def atom_feed(params={})
	  return
		require 'builder'
		require 'time'
		prepare_feed params
		buffer = ''
		xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)
		xml.instruct!
		xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
			xml.id      @site.config[:base_url] + '/'
			xml.title   @item[:title]
			xml.updated @item[:last][:date].to_iso8601_time
			xml.link(:rel => 'alternate', :href => @site.config[:base_url])
			xml.link(:rel => 'self', :href => @site.config[:base_url]+"/#{@item[:permalink]}/")
			xml.author do
				xml.name  @item[:author_name]
				xml.uri   @item[:author_uri]
			end
			count = 0
			@item[:articles].each do |a|
				xml.entry do
					xml.id        atom_tag_for(a)
					xml.title     a[:title]
					xml.published a[:date].to_iso8601_time
					# Subtract a few seconds to avoid having the same update time (compilation time)
					xml.updated((a.mtime-count).to_iso8601_time)
					count = count+1
					xml.link(:rel => 'alternate', :href => url_for(a))
					[*a[:tags]].each do |t|
						xml.category(:term => t, :scheme => "#{@site.config[:base_url]}/tags/#{t}/")
					end
					summary = @item[:excerpt_proc].call(a)
					xml.summary   summary, :type => 'html' unless summary.nil?
					xml.content(:type => 'html') do |c|
						c << %{<![CDATA[\n#{@item[:content_proc].call(a)}]]>\n}
					end
				end
			end
		end
		buffer
	end

	def atom_tag_for(item)
		require 'time'
		hostname        = @site.config[:base_url].sub(/.*:\/\/(.+?)\/?$/, '\1')
		formatted_date  = item[:date].to_iso8601_date
		'tag:' + hostname + ',' + formatted_date + ':' + (item.reps[0].path || item.identifier)
	end

	def latest_articles(max=nil)
		total = @site.items.select{|p| p.attributes[:type] == 'article'}.sort{|a, b| a.attributes[:date] <=> b.attributes[:date]}.reverse
		max ||= total.length
		total[0..max-1]
	end

	def popular_articles(max=nil)
		total = @site.items.select{|p| p.attributes[:date] && p.attributes[:type] == 'article' && p.attributes[:popular]}.sort{|a, b| a.attributes[:date] <=> b.attributes[:date]}.reverse
		max ||= total.length
		total[0..max-1]
	end

	def by_permalink(articles, permalink)
		articles.select{|a| a[:permalink] == permalink}[0] rescue nil
	end

	def articles_by_month
		articles = latest_articles
		m_articles = []
		index = -1
		current_month = ""
		articles.each do |a|
			next unless a.attributes[:date]
			month = a.attributes[:date].strftime("%B %Y")
			if current_month != month then
				# new month
				m_articles << [month, [a]]
				index = index + 1
				current_month = month
			else
				# same month
				m_articles[index][1] << a
			end
		end
		m_articles
	end

	def month_link_with_count(month, count)
		permalink = month.downcase.gsub /\s/, '-'
		%{<a href="/archives/#{permalink}/">#{month}</a> (#{count})}
	end

end
