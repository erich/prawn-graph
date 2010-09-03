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
      def initialize(data, document, options = {})
        if options[:at].nil? || options[:at].empty?
          raise Prawn::Errors::NoGraphStartSet,
            "you must specify options[:at] as the coordinates where you" +
            " wish this graph to be drawn from."
        end
        opts = { :theme => Prawn::Chart::Themes.monochrome, :width => 500, :height => 200, :spacing => 20 }.merge(options)
        @raw_options = opts
        (@headings, @values, @highest_value) = process_the data
        @lowest_value = options[:minimum_value] ? options[:minimum_value] : 0
        @highest_value = options[:maximum_value] if options[:maximum_value]
        @value_transform = options[:transform] if Proc === options[:transform]
        @downwards = options[:downward] || options[:downwards] || false
        (grid_x_start, grid_y_start, grid_width, grid_height) = parse_sizing_from opts 
        @colour = (!opts[:use_color].nil? || !opts[:use_colour].nil?)
        @document = document
        @theme = opts[:theme]
        off = 20
        @marker_values = opts[:marker_values]
        marker_points = @marker_values ? @marker_values.collect{|v|calculate_point_fraction_from(v)} : nil
        @grid = Prawn::Chart::Grid.new(grid_x_start, grid_y_start, grid_width, grid_height, opts[:spacing], marker_points, document, @theme, @downwards)
      end
  
      # Draws the graph on the document which we have a reference to.
      #
      def draw
        draw_bounding_box
        @grid.draw
        label_axes
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
        @document.fill_color @theme.background_colour
        @document.fill_and_stroke_rectangle [(@point.first - 10), (@point.last + ( @total_height + 40 ))], @document.bounds.width, (@total_height + 40)
        @document.fill_color '000000'
      end   
 
      def label_axes
        @document.fill_color @theme.font_colour
        base_x = @grid.start_x + 1
        base_y = @grid.start_y + 1

        # Put the values up the Y Axis
        #
        x_point = base_x - (4 + 4*"#{@highest_value}".length)
        @document.draw_text @downwards ? @lowest_value : @highest_value, :at => [x_point, base_y + @grid.height - 3], :size => 6
        @document.draw_text @downwards ? @highest_value : @lowest_value, :at => [x_point, base_y - 1], :size => 6
        @marker_values.each do |value|
          next if value == @lowest_value || value == @highest_value
          @document.draw_text value, :at => [x_point, base_y + calculate_point_height_from(value) - 2], :size => 6
        end if @marker_values

        # Put the column headings along the X Axis
        #
        point_spacing = calculate_plot_spacing 
        # last_position = base_x + (point_spacing / 2)
        last_position = base_x
        @headings.each do |heading|
          heading_text = @raw_options[:heading_printer] ? @raw_options[:heading_printer].call(heading) : heading
          # @document.draw_text heading_text, :at => [last_position, base_y - 15 ], :size => 5
          @document.text_box heading_text, :at => [last_position+1, base_y - 10 ], :size => 5, :width => point_spacing-2, :align => :center, :overflow => :ellipses
          last_position += point_spacing
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
        x_offset = 15
        y_offset = 0
        move_y_up = 0
        grid_width = o[:width]
        grid_height = o[:height]
      
        @total_width = o[:width]
        @total_height = o[:height]
        @point = o[:at].dup 

        # Make room for the title if we're choosing to Render it.
        #
        if o[:title]
          @title = o[:title]
          y_offset += 10 
        end

        # Make room for X Axis labels if we're using them.
        #
        if o[:label_x]
          y_offset += 30
          move_y_up += 30
          @x_label = o[:label_x]
        end

        # Make room for Y Axis labels if we're using them.
        #
        if o[:label_y]
          @y_label = o[:label_y]
          x_offset += 15
        end

 
        # Return the values calculated here.
        #
        [ (o[:at][0] + x_offset), (o[:at][1] + move_y_up + 20), (grid_width - (x_offset - 20)), (grid_height - y_offset) ]
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

      def calculate_plot_spacing
        (@grid.width / @headings.length)
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
        @downwards ? (gh-ph) : ph
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
