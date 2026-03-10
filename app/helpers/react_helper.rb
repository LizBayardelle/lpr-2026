module ReactHelper
  def react_component(name, props = {})
    content_tag(:div, "", data: { react_component: name, react_props: props.to_json })
  end
end
