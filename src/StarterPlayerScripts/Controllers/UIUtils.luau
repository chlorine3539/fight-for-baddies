local UIUtils = {}

function UIUtils.addSizeConstraints(instance, minWidth, maxWidth, minHeight, maxHeight)
	local constraint = Instance.new("UISizeConstraint", instance)
	constraint.MinSize = Vector2.new(minWidth, minHeight)
	constraint.MaxSize = Vector2.new(maxWidth, maxHeight)
	return constraint
end

function UIUtils.addTextConstraints(instance, minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint", instance)
	constraint.MinTextSize = minSize
	constraint.MaxTextSize = maxSize
	return constraint
end

return UIUtils
