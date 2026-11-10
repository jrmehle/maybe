class TabsComponentPreview < ViewComponent::Preview
  def default
    render DS::Tabs.new(active_tab: "tab1") do |tabs|
      tabs.with_nav do |nav|
        nav.with_btn(id: "tab1", label: "Tab 1")
        nav.with_btn(id: "tab2", label: "Tab 2")
      end

      tabs.with_panel(tab_id: "tab1") { content_tag(:p, "Content for tab 1") }
      tabs.with_panel(tab_id: "tab2") { content_tag(:p, "Content for tab 2") }
    end
  end

  def custom
    render DS::Tabs.new(
      variant: :unstyled,
      active_tab: "tab1",
      active_btn_classes: "bg-white text-primary",
      inactive_btn_classes: "text-secondary",
    ) do |tabs|
      <div class="flex border border-secondary rounded-lg h-full max-w-[400px]">
        <%= tabs.with_nav(classes: "flex flex-col py-2 px-3 border-r border-secondary") do |nav| %>
          <%= nav.with_btn(id: "tab1", label: "Tab 1", classes: "px-2 py-1 rounded-md w-full whitespace-nowrap") %>
          <%= nav.with_btn(id: "tab2", label: "Tab 2", classes: "px-2 py-1 rounded-md w-full whitespace-nowrap") %>
        <% end %>

        <div class="flex flex-col w-full">
          <div class="h-[200px] p-4">
            <%= tabs.with_panel(tab_id: "tab1") { content_tag(:p, "Content for tab 1") } %>
            <%= tabs.with_panel(tab_id: "tab2") { content_tag(:p, "Content for tab 2") } %>
          </div>

          <div class="w-full border-t border-secondary p-4">Footer</div>
        </div>
      </div>
    end
  end
end
