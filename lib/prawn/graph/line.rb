module Prawn
  module Chart
    
    # Prawn::Chart::Line plots its values as a Line graph, relatively
    # sized to fit within the space defined by the Prawn::Chart::Grid
    # associated with it.
    #
    # Call to new will return a new instance of Prawn::Chart::Line ready to
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

    class Line < Base

      private
      
      def plot_values
        base_x = @grid.start_x + 1
        base_y = @grid.start_y + 0
        bar_width = calculate_bar_width
        point_spacing = calculate_plot_spacing
        @values.reverse_each_with_index do |data_set, setidx|
          p = [ ]
          # last_position = base_x + bar_width
          last_position = base_x + (point_spacing / 2)
          # last_position = base_x
          @headings.each do |heading|
            value = data_set[heading]
            if value
              bar_height = calculate_point_height_from value
              point = [last_position, base_y + bar_height]
              p << point
            else
              p << nil
            end
            last_position += point_spacing
          end
          @document.line_width 2
          @document.fill_color 'FFFFFF'
          @document.stroke_color @theme.colours[setidx % @theme.colours.length]
          p[0..-2].each_with_index do |point,i|
            if point
              @document.move_to point
              @document.stroke_line_to p[i+1] if p[i+1]
            end
          end
          @document.line_width 1
          p.each_with_index do |point,i|
            if point
              @document.fill_circle_at point, :radius => 2
              @document.stroke_circle_at point, :radius => 2
            end
          end
        end
        
      end

    end
  end
end
