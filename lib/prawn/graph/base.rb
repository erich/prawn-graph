module Prawn
  module Chart
    
    # Prawn::Chart::Base implements the common methods shared by most of the graphs
    # and charts whcih will need to be plotted. 
    #
    # All Prawn::Chart::Base instances and their children will have the following
    # associated with them:
    #
    #   1. A Prawn::Chart::Grid  which is where the graph will be drawn
    #   2. A refernce to the Prawn::Document being affected
    #   3. A set of data to be plotted.
    #
    # A public draw method is available which does what it says on the tin and... 
    # well.. draws the graph on the document it has a reference to.
    #
    class Base
      
      attr_accessor :grid, :headings, :values, :highest_value, :document, :colour
      
      # Returns a new instance of a graph to be drawn, really only useful for the
      # subclasses which actually have a plot_values method declared so the data
      # is actually rendered as a graph.
      #
      # Takes an Array of +data+, which should contain complete rows of data for
      # values to be plotted; a reference to a +document+ which should be an 
      # instance of Prawn::Document and an +options+ with at least a value for :at
      # specified.
      #
      # Options are:
      #
      #  :at , which should be an Array representing the point at which the graph
      #  should be drawn.
      #
      #  :title, the title for this graph, wil be rendered centered to the top of 
      #  the Grid.
      #
      #  :label_x, a label to be shown along the X axis of he graph, rendered centered
      #  on the grid.
      #
      #  :label_y, a label to be shown along the Y axis of he graph, rendered centered
      #  on the grid and rotated to be perpendicular to the axis.
      #
      # :theme, the theme to be used to draw this graph, defaults to monochrome.
      #
      def initialize(data, document, opts = {})
        if opts[:at].nil? || opts[:at].empty?
          raise Prawn::Errors::NoGraphStartSet,
            "you must specify options[:at] as the coordinates where you" +
            " wish this graph to be drawn from."
        end
        @document = document
        @options = { :theme => Prawn::Chart::Themes.monochrome, :width => 500, :height => 200, :spacing => 20, :direction => :vertical, :label_axes => true, :draw_grid => true }.merge(opts)
        @theme = @options[:theme]
        @direction = @options[:direction]
        @setAxis = (@direction == :horizontal) ? :yaxis : :xaxis
        @valueAxis = (@direction == :horizontal) ? :xaxis : :yaxis
        @setAxisMode = @options[@setAxis][:mode] || :normal
        (@setAxisHeadings, @values, @highest_value) = process_the data
        @lowest_value = @options[:minimum_value] ? @options[:minimum_value] : 0
        if @options[:maximum_value]
          @highest_value = @options[:maximum_value]
          @highest_value += 1 if @highest_value == @lowest_value
        else
          maximumValue = @highest_value.to_f
          maximumValue += 1 if maximumValue == @lowest_value
          delta = maximumValue - @lowest_value
          margin = (@options[:autoscaleMargin] || 0.025) * delta
          @lowest_value -= margin if @lowest_value != 0
          maximumValue += margin
          delta = maximumValue - @lowest_value
          magnitude = Math.log10(delta).floor
          normalized = delta / (10**magnitude)
          normalized = (normalized * 4.0).ceil / 4.0
          normalized = normalized * (10**magnitude)
          normalized = normalized.ceil
          @highest_value = (@lowest_value + normalized).to_i
        end
        
        [:xaxis,:yaxis].each do |axis|
          if @options[axis][:autoticks]
            increment = 5
            if delta = (axis == @valueAxis ? (@highest_value - @lowest_value) : (@setAxisHeadings.last - @setAxisHeadings.first rescue nil))
              [9,6,8,7,5,4,3,2,1].each do |i|
                if (delta.to_f / i.to_f) == (delta.to_f / i.to_f).floor
                  increment = i
                  break
                end
              end
              @options[axis][:spacing] = @options[axis == :xaxis ? :width : :height] / increment,
              @options[axis][:marker_values] = ((0..increment).collect {|i| i * delta / increment })
            end
          end
        end
        
        @value_transform = @options[:transform] if Proc === @options[:transform]
        @inverted = @options[@valueAxis][:inverted] || @options[:downward] || @options[:downwards] || false
        @bounding_margin = [(@options[:margin] || 10).to_i, 0].max
        
        if @setAxis == :yaxis
          p=@options[@setAxis][:heading_printer]
          @options[:left_margin] = [@document.font.compute_width_of(@setAxisHeadings.collect{|h|p ? p.call(h) : h.to_s}.sort{|a,b|a.length<=>b.length}.last, :size => 5), 60].min
        end
        (grid_x, grid_y, grid_width, grid_height) = parse_sizing_from @options
        
        @valueAxisHeadings = @options[@valueAxis][:marker_values]
        marker_points = @valueAxisHeadings ? @valueAxisHeadings.collect{|v|calculate_point_fraction_from([*v].first)} : nil
        
        @grid = Prawn::Chart::Grid.new(grid_x, grid_y, grid_width, grid_height, document, @theme,
                                       :spacing => @options[:spacing],
                                       (@direction == :horizontal ? :x_markers : :y_markers) => marker_points,
                                       (@direction == :horizontal ? :reverse_x : :reverse_y) => @inverted)
      end
  
      # Draws the graph on the document which we have a reference to.
      #
      def draw
        draw_bounding_box
        @grid.draw if @options[:draw_grid]
        label_axes if @options[:label_axes]
        if @title
          draw_title
        end
        plot_values
        if @x_label
          draw_x_axis_label
        end 
        if @y_label
          draw_y_axis_label
        end 
       reset
      end

      private

      def draw_bounding_box
        return if @bounding_margin == 0
        @document.fill_color @theme.background_colour
        @document.fill_and_stroke_rectangle [@point.first, @point.last + @total_height], @document.bounds.width, @total_height
        @document.fill_color '000000'
      end   
 
      def label_axes
        @document.fill_color @theme.font_colour
        base_x = @grid.start_x + 1
        base_y = @grid.start_y + 1

        # Put the values along the value axis
        #
        if @direction == :horizontal
          y_point = base_y
          if @valueAxisHeadings
            @valueAxisHeadings.each do |value|
              w = @document.font.compute_width_of(value.to_s, :size => 6)
              @document.draw_text value, :at => [base_x + calculate_point_width_from(value) - w/2.0, y_point - 7], :size => 6
            end
          else
            w = @document.font.compute_width_of((@inverted ? @lowest_value : @highest_value).to_s, :size => 6)
            @document.draw_text @inverted ? @lowest_value : @highest_value, :at => [base_x + @grid.height - w, y_point - 7], :size => 6
            @document.draw_text @inverted ? @highest_value : @lowest_value, :at => [base_x - 1, y_point - 7], :size => 6
          end
        else
          x_point = base_x - (4 + 4*"#{@highest_value}".length)
          if @valueAxisHeadings
            @valueAxisHeadings.each do |value|
              @document.draw_text value, :at => [x_point, base_y + calculate_point_height_from(value) - 2], :size => 6
            end
          else
            @document.draw_text @inverted ? @lowest_value : @highest_value, :at => [x_point, base_y + @grid.height - 3], :size => 6
            @document.draw_text @inverted ? @highest_value : @lowest_value, :at => [x_point, base_y - 1], :size => 6
          end
        end

        # Put the column headings along the set axis
        #
        printedHeadings = {}
        point_spacing = calculate_plot_spacing
        if @direction == :horizontal
          last_position = base_y + point_spacing/1.25
          @setAxisHeadings.each_with_index do |heading, idx|
            heading_text = @options[@setAxis][:heading_printer] ? @options[@setAxis][:heading_printer].call(heading) : heading.to_s
            next if printedHeadings[heading_text]
            y_position = @setAxisMode==:time ? calculate_y_offset(heading, idx) : last_position+(point_spacing * idx)
            @document.text_box heading_text, :at => [base_x - @options[:left_margin], y_position], :size => 5, :width => @options[:left_margin]-4, :align => :left, :overflow => :ellipses
            printedHeadings[heading_text] = true
          end
        else
          last_position = base_x
          @setAxisHeadings.each_with_index do |heading, idx|
            heading_text = @options[@setAxis][:heading_printer] ? @options[@setAxis][:heading_printer].call(heading) : heading.to_s
            next if printedHeadings[heading_text]
            headingWidth = @setAxisMode==:time ? calculate_heading_widths : point_spacing-2
            x_position = @setAxisMode==:time ? calculate_x_offset(heading, idx)-(headingWidth/2) : last_position+(point_spacing * idx)
            @document.text_box heading_text, :at => [x_position, base_y - 7 ], :size => 5, :width => headingWidth, :align => :center, :overflow => :ellipses
            printedHeadings[heading_text] = true
          end
        end
        
        @document.fill_color @theme.background_colour
      end

      def draw_title
        @document.fill_color @theme.font_colour
        x_coord = calculate_x_axis_center_point(@title, 10)
        y_coord = @grid.start_y + @grid.height + 10
        @document.draw_text @title, :at => [x_coord, y_coord] ,:size => 10
        @document.fill_color @theme.background_colour
      end

      def draw_x_axis_label
        @document.fill_color @theme.font_colour
        x_coord = calculate_x_axis_center_point(@x_label, 8)
        y_coord = @grid.start_y - 30
        @document.draw_text @x_label, :at => [x_coord, y_coord] ,:size => 8
        @document.fill_color @theme.background_colour
      end

      def draw_y_axis_label
        @document.fill_color @theme.font_colour
        y_coord = calculate_y_axis_center_point(@y_label, 8)
        x_coord = @grid.start_x - 30
        @document.draw_text @y_label, :at => [x_coord, y_coord] ,:size => 8, :rotate => 90
        @document.fill_color @theme.background_colour
      end
      
      # All subclasses of Prawn::Chart::Base must implement thier own plot_values
      # method, which does the actual real heavy lifting of drawing the graph.
      #
      def plot_values
        raise Prawn::Errors::NoPlotValuesMethod, 'subclasses of Prawn::Chart::Base must implement '
                                              +  'their own plot_values method.'
      end

      def reset
        @document.line_width 1
        @document.stroke_color '000000'
        @document.fill_color '000000'
        @document.move_to @grid.point
      end


      # Utility methods for dealing with working out where things should be
      # the calculations and such done here are all very rough, but are
      # sufficient for now to plot just what we need.
      #
      
      
      def parse_sizing_from(o)
        grid_width = o[:width]
        grid_height = o[:height]
      
        @total_width = o[:width]
        @total_height = o[:height]
        @point = o[:at].dup
        
        o[:left_margin] ||= 15

        gridPointX = o[:at][0] + o[:left_margin] + @bounding_margin
        gridPointY = o[:at][1] + 7 + @bounding_margin
        gridWidth = @total_width - (2 * @bounding_margin) - o[:left_margin]
        gridHeight = @total_height - (2 * @bounding_margin) - 7
        
        # Make room for the title if we're choosing to Render it.
        #
        if o[:title]
          @title = o[:title]
          gridHeight -= 10
        end

        # Make room for X Axis labels if we're using them.
        #
        if o[:label_x]
          gridPointY += 30
          gridHeight -= 30
          @x_label = o[:label_x]
        end

        # Make room for Y Axis labels if we're using them.
        #
        if o[:label_y]
          @y_label = o[:label_y]
          gridPointX += 15
          gridWidth -= 15
        end
        
        if @highest_value > 999
          offset = 4 * ("#{@highest_value}".length - 3)
          gridPointX += offset
          gridWidth -= offset
        end
        
        # Return the values calculated here.
        #
        [gridPointX, gridPointY, gridWidth, gridHeight]
      end

      def process_the(data_array)
        col = []
        val = []
        greatest_val = 0
        data_array = [data_array] unless Array === data_array.first
        data_array.each do |data_set|
          set_data = {}
          set_columns = []
          data_set.each do |data_point|
            set_data[data_point[0]] = data_point[1]
            set_columns << data_point[0]
            greatest_val = [greatest_val, data_point[1]].max if data_point[1]
          end
          val << set_data
          col << set_columns
        end
        col = col[0].zip(*col[1..-1]).flatten.compact.uniq
        col = col.sort if col.all?{|v|Comparable === v && !(String === v)}
        [ col, val, greatest_val ]
      end

      def calculate_x_axis_center_point(text, text_size, graph_start_x = @grid.start_x, graph_width = @grid.width)
        ((graph_start_x + (graph_width / 2)) - ((text.length * text_size) / 4))
      end
      alias calculate_x_axis_centre_point calculate_x_axis_center_point

      def calculate_y_axis_center_point(text, text_size, graph_start_y = @grid.start_y, graph_height = @grid.height)
        ((graph_start_y + (graph_height / 2)) - ((text.length * text_size) / 4))
      end
      alias calculate_y_axis_centre_point calculate_y_axis_center_point
      
      def calculate_x_axis_scale
        @minimumHeading ||= @setAxisHeadings.min
        @maximumHeading ||= @setAxisHeadings.max
        @xAxisScale ||= if @maximumHeading > @minimumHeading
          (@grid.width - calculate_bar_width) / (@maximumHeading - @minimumHeading)
        else
          @grid.width
        end
      end
      def calculate_x_offset value, index
        case @setAxisMode
          when :time
            calculate_x_axis_scale
            if @xAxisScale == @grid.width
              @xAxisScale / 2
            else
              @grid.start_x + (calculate_bar_width / 2) + (value - @minimumHeading) * @xAxisScale
            end
          else
            @grid.start_x + index * calculate_plot_spacing + 1
        end
      end
      def calculate_y_axis_scale
        @minimumHeading ||= @setAxisHeadings.min
        @maximumHeading ||= @setAxisHeadings.max
        @yAxisScale ||= if @maximumHeading > @minimumHeading
          (@grid.height - calculate_bar_width) / (@maximumHeading - @minimumHeading)
        else
          @grid.height
        end
      end
      def calculate_y_offset value, index
        case @setAxisMode
          when :time
            calculate_y_axis_scale
            if @yAxisScale == @grid.height
              @yAxisScale / 2
            else
              @grid.start_y + (calculate_bar_width / 2) + (value - @minimumHeading) * @yAxisScale
            end
          else
            @grid.start_y + index * calculate_plot_spacing + 1
        end
      end
      def calculate_heading_widths
        case @setAxisMode
          when :time
            # calculate_x_axis_scale
            @setAxis == :xaxis ?
              30 :
              @document.font.compute_width_of(@setAxisHeadings.sort{|a,b|a.length<=>b.length}.last, :size => 5)
          else
            @setAxis == :xaxis ?
              (calculate_plot_spacing - 2) :
              @document.font.compute_width_of(@setAxisHeadings.sort{|a,b|a.length<=>b.length}.last, :size => 5)
        end
      end

      def calculate_plot_spacing
        @direction == :horizontal ? ((@grid.height / @setAxisHeadings.length)) : (@grid.width / @setAxisHeadings.length)
      end

      def calculate_bar_width
        calculate_plot_spacing / 2
      end

      def calculate_point_fraction_from(column_value)
        cv = transform_value BigDecimal("#{column_value}")
        hv = transform_value BigDecimal("#{@highest_value}")
        lv = transform_value BigDecimal("#{@lowest_value}")
        (cv-lv) / (hv-lv)
      end
      
      def calculate_point_height_from(column_value)
        fraction = calculate_point_fraction_from column_value
        gh = BigDecimal("#{@grid.height}")
        ph = (gh * fraction).to_i
        v=@inverted ? (gh-ph) : ph
        v
      end
      def calculate_point_width_from(column_value)
        fraction = calculate_point_fraction_from column_value
        gw = BigDecimal("#{@grid.width}")
        pw = (gw * fraction).to_i
        v=@inverted ? (gw-pw) : pw
        v
      end
      
      def transform_value value
        if @value_transform
          @value_transform.call(value) rescue value
        else
          value
        end
      end


    end
  end
end
