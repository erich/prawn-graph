module Prawn
  module Chart
    
    # Prawn::Chart::Bar plots its values as a Bar graph, relatively
    # sized to fit within the space defined by the Prawn::Chart::Grid
    # associated with it.
    #
    # Call to new will return a new instance of Prawn::Chart::Bar ready to
    # be rendered.
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
    # Data should be formatted like:
    #
    #    [
    #      [ 'Column Heading', SomeValue ],
    #      [ 'Column Heading', SomeValue ],
    #      [ 'Column Heading', SomeValue ],
    #      [ 'Column Heading', SomeValue ],
    #      [ 'Column Heading', SomeValue ],
    #      [ 'Column Heading', SomeValue ]
    #    ]
    #
    class Bar < Base

  
      private

      def calculate_plot_spacing
        divisor = @options[:ignore_set_spacing] ? @values.collect{|ds|ds.values}.compact.length : @setAxisHeadings.length
        (@direction == :horizontal ? @grid.height : @grid.width) / divisor
      end

      def plot_values
        base_x = @grid.start_x #+ (@inverted ? -1 : 1)
        far_x = base_x + @grid.width
        base_y = @grid.start_y #+ (@inverted ? -1 : 1)
        far_y = base_y + @grid.height
        
        bar_width = @options[:ignore_set_spacing] ? calculate_bar_width : calculate_bar_width / @values.length
        @document.line_width bar_width
        value_printer = @options[@valueAxis][:value_printer]
        labelSize = bar_width/2
        barYOffset = (calculate_plot_spacing / 2) / @values.length
        
        @values.reverse_each_with_index do |data_set, setidx|
          
          @setAxisHeadings.each_with_index do |heading, idx|
            value = data_set[heading]
            
            if value
              @document.stroke_color @theme.next_colour
              if @direction == :horizontal
                y_position = calculate_y_offset(heading, idx) + (@options[:ignore_set_spacing] ? 0 : bar_width * setidx) + barYOffset
                bar_length = calculate_point_width_from value
                @document.move_to [@inverted ? far_x : base_x, y_position]
                @document.stroke_line_to [base_x + bar_length, y_position]
                if @options[@valueAxis][:label_values]
                  value_text = value_printer ? value_printer.call(value) : value.to_s
                  value_width = @document.font.compute_width_of(value_text, :size => labelSize) + 2
                  labelPos = [base_x + bar_length + (@inverted ? -(value_width+1) : 1), y_position + bar_width/2]
                  @document.mask(:fill_color) do
                    @document.fill_color = 'ffffff'
                    @document.fill_rectangle labelPos, value_width, bar_width
                    @document.fill_color = '000000'
                    @document.text_box value_text, :at => labelPos,
                                                   :width => value_width, :height => bar_width, :size => labelSize, :margin => 0,
                                                   :align => (@inverted ? :right : :left), :valign => :center,
                                                   :overflow => :shrink_to_fit, :min_font_size => 7
                  end
                end
              else
                x_position = calculate_x_offset(heading, idx) + (@options[:ignore_set_spacing] ? 0 : bar_width * setidx)
                bar_length = calculate_point_height_from value
                @document.move_to [x_position, @inverted ? far_y : base_y]
                @document.stroke_line_to [x_position, base_y + bar_length]
                if @options[@valueAxis][:label_values]
                  value_text = value_printer ? value_printer.call(value) : value.to_s
                  value_width = @document.font.compute_width_of(value_text, :size => labelSize) + 2
                  labelPos = [x_position - value_width/2, base_x + bar_length + (@inverted ? -1 : (labelSize+1))]
                  @document.mask(:fill_color) do
                    @document.fill_color = 'ffffff'
                    @document.fill_rectangle labelPos, value_width, labelSize
                    @document.fill_color = '000000'
                    @document.text_box value.to_s, :at => labelPos,
                                                   :width => value_width, :height => labelSize, :size => labelSize, :margin => 0,
                                                   :align => :center, :valign => (@inverted ? :top : :bottom)
                  end
                end
              end
            end
            
          end
          
        end
      end

    end
  end
end
