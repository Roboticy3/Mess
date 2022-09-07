extends Line2D

#LineGraph class by Pablo Ibarz
#created August 2022

#attach a graph to a Line2D and fit the values to the screen

export var flip_y := false

export var corner_pos := Vector2(1000, 100)
export var corner_size := Vector2(800, 700)

export var data_pos := Vector2(0, 0)
export var data_size := Vector2(300, 10000)

export var data:PoolVector2Array

#apply data to the graph, transforming data from the data top-bottom ranges to the corner ranges
func apply() -> void:
	
	#create a new array of points
	var temp := PoolVector2Array()
	temp.resize(min(data_size.x, data.size()))
	
	var start := max(data.size() - data_size.x,0)
	for i in temp.size():
		
		#get the position of data[i] in the data rectangle
		var p := (data[i + start] - Vector2(start, 0)) / data_size
		if flip_y: p.y = 1 - p.y
		
		#add the transformed data to points, fitting it between the top and bottom corners
		temp[i] = corner_pos + p * corner_size
	
	#set points to the new array
	points = temp

#functions to update data and also call apply
func append(var y:float):
		
	data.append(Vector2(data.size(), y))
	apply()

func remove(var i:int):
	data.remove(i)
	apply()

#replace data with new array
func set_data(var a:Array):
	for i in a.size():
		data.append(Vector2(i,a[i]))
	apply()
