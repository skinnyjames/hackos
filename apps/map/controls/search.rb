module HackOS::Maps
  module Controls
    class SearchResult < Hokusai::Block
      style <<-EOF
      [style]
      resultContainer {
        background: rgb(22,22,22,0);
        padding: padding(8.0, 6.0, 8.0, 6.0);
        outline: outline(0.0, 0.0, 1.0, 0.0);
        outline_color: rgb(217, 215, 215);
      }
      resultContainer@hover {
        background: rgb(211,211,211);
      }
      EOF
      
      template <<-EOF
      [template]
        vblock { ...resultContainer @tap="select_address" }
          text { :content="label" @height_updated="update_height" }
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        text: Hokusai::Blocks::Text,
      )
      
      inject :mcontrol
      computed! :address

      def select_address(event)
        mcontrol.directions(address)
      end

      def label
        mcontrol.label_for_address(address)
      end

      def update_height(height)
        node.meta.set_prop(:height, height + 18.0);
      end
    end

    class Search < Hokusai::Block
      style <<-EOF
      [style]
      searchContainer {
        rounding: 0.1;
        background: rgb(255, 255, 255);
        z: 2;
        outline: outline(1.0, 1.0, 1.0, 1.0);
        outline_color: rgb(194, 194, 194);
        zposition: bounds(10.0, 20.0, 0.0, 20.0);      
      }
      searchBar {
        height: 40.0;
        outline: outline(0.0, 0.0, 0.5, 0.0)
        outline_color: rgb(194, 194, 194);
      }
      input {
        placeholder: "Search address";
        placeholder_size: 19;
        background: rgb(255,255,255, 0);
        color: rgb(22,22,22);
        padding: padding(8.0, 5.0, 0.0, 5.0);
        size: 22;
        rounding: 0.1;
      }
      icon {
        width: 36.0;
        size: 22;
        color: rgb(42, 43, 62);
      }
      icon@hover {
        color: rgb(76, 83, 201);
      }
      searchResultsContainer {
        height: 500.0;
      }
      error {
        z: 2;
        ztarget: "parent";
        zposition: bounds(0.0, 2.0, 2.0, 2.0);
      }
      searchError {
        background: rgb(184, 66, 66);
      }
      searchErrorText {
        color: rgb(255,255,255);
      }
      EOF

      template <<-EOF
      [template]
      vblock { ...searchContainer :height="search_container_height" :width="mcontrol.search_width" }
        hblock { ...searchBar :height="search_height" }
          selectable { :selection_override="selection" :cursor_width="2.0" }
            input { :model="term" @change="search" ...input }
          icon { type="magnify" ...icon @tap="search" }
          icon { type="microphone" ...icon }
        [if="has_search_results"]
          panel { ...searchResultsContainer }
            [for="result in search_results"]
              result { :key="result_label(result) :address="result" }

      EOF

      uses(
        result: HackOS::Controls::SearchResult,
        text: Hokusai::Blocks::Text,
        panel: Hokusai::Blocks::Panel,
        vblock: Hokusai::Blocks::Vblock,
        hblock: Hokusai::Blocks::Hblock,
        icon: Hokusai::Blocks::Icon,
        selectable: Hokusai::Blocks::Selectable,
        input: HackOS::Input
      )

      inject :mcontrol

      attr_accessor :term
      attr_reader :selection

      computed :search_height, default: 40.0, convert: proc(&:to_f)

      def initialize(**args)
        @term = ""
        @selection = Hokusai::Util::Selection.new
        super
      end

      def search_results
        mcontrol.search_results
      end

      def result_label(result)
        mcontrol.label_for_address(result)
      end

      def has_search_results
        !mcontrol.search_results.empty?
      end

      def has_search_error
        !!mcontrol.search_results_error
      end

      def search_container_height
        has_search_results ? search_height + 500.0 : search_height
      end

      def search(event)
        mcontrol.search(term)
        self.selection.clear
        self.term = ""
      end
    end
  end
end