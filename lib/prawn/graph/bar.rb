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

      def plot_values
        base_x = @grid.start_x + 1
        base_y = @grid.start_y + 1
        top_y = @grid.start_y + @grid.height + 10
        
        bar_width = calculate_bar_width / @values.length
        @document.line_width bar_width

        @values.reverse_each_with_index do |data_set, setidx|
          
          @setAxisHeadings.each_with_index do |heading, idx|
            value = data_set[heading]
            
            if value
              @document.stroke_color @theme.next_colour
              if @direction == :horizontal
                y_position = top_y + calculate_y_offset(heading, idx) - (bar_width * setidx)
                bar_width = calculate_point_width_from value
                @document.move_to [base_x, y_position]
                @document.stroke_line_to [base_x + bar_width, y_position]
              else
                x_position = base_x + calculate_x_offset(heading, idx) + (bar_width * setidx)
                bar_height = calculate_point_height_from value
                @document.move_to [x_position, base_y]
                @document.stroke_line_to [x_position, base_y + bar_height]
              end
            end
            
          end
          
        end
      end

    end
  end
end
