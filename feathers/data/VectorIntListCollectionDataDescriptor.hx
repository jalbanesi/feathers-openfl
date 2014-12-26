/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data;
import flash.errors.IllegalOperationError;

/**
 * An <code>IListCollectionDataDescriptor</code> implementation for Vector.&lt;int&gt;.
 * 
 * @see ListCollection
 * @see IListCollectionDataDescriptor
 */
class VectorIntListCollectionDataDescriptor implements IListCollectionDataDescriptor
{
	/**
	 * Constructor.
	 */
	public function VectorIntListCollectionDataDescriptor()
	{
	}
	
	/**
	 * @inheritDoc
	 */
	public function getLength(data:Object):int
	{
		this.checkForCorrectDataType(data);
		return (data as Vector.<int>).length;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getItemAt(data:Object, index:int):Object
	{
		this.checkForCorrectDataType(data);
		return (data as Vector.<int>)[index];
	}
	
	/**
	 * @inheritDoc
	 */
	public function setItemAt(data:Object, item:Object, index:int):Void
	{
		this.checkForCorrectDataType(data);
		(data as Vector.<int>)[index] = item as int;
	}
	
	/**
	 * @inheritDoc
	 */
	public function addItemAt(data:Object, item:Object, index:int):Void
	{
		this.checkForCorrectDataType(data);
		(data as Vector.<int>).splice(index, 0, item);
	}
	
	/**
	 * @inheritDoc
	 */
	public function removeItemAt(data:Object, index:int):Object
	{
		this.checkForCorrectDataType(data);
		return (data as Vector.<int>).splice(index, 1)[0];
	}

	/**
	 * @inheritDoc
	 */
	public function removeAll(data:Object):Void
	{
		this.checkForCorrectDataType(data);
		(data as Vector.<int>).length = 0;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getItemIndex(data:Object, item:Object):int
	{
		this.checkForCorrectDataType(data);
		return (data as Vector.<int>).indexOf(item as int);
	}
	
	/**
	 * @private
	 */
	private function checkForCorrectDataType(data:Object):Void
	{
		if(!(data is Vector.<int>))
		{
			throw new IllegalOperationError("Expected Vector.<int>. Received " + Object(data).constructor + " instead.");
		}
	}
}