module ChartHelper
  def most_downloaded_chart(rubygems)
    downloads = rubygems.map(&:downloads)

    # GoogleChart will error out if all the values are zero...
    return if downloads.all? { |count| count == 0 }

    chart = GoogleChart::BarChart.new do |bc|
      bc.width       = 666
      bc.height      = 360
      bc.title       = 'Most Downloads'
      bc.orientation = :horizontal

      bc.axis :left,
              :labels    => rubygems.map { |rubygem|
                              "#{rubygem.name} (#{rubygem.downloads})"
                            }.reverse,
              :color     => '555555',
              :font_size => 12,
              :alignment => :center
      bc.axis :bottom,
              :range     => [0, downloads.max],
              :color     => '555555',
              :font_size => 12,
              :alignment => :center
      bc.data '', downloads, '8B0000'
      bc.show_legend = false
    end

    image_tag chart.to_url
  end
end
