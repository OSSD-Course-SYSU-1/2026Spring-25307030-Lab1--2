def bubble_sort(arr):
    """使用冒泡排序对列表进行原地排序，并返回排序结果。"""
    n = len(arr)
    for i in range(n - 1):
        swapped = False
        for j in range(n - 1 - i):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break
    return arr


if __name__ == '__main__':
    data = [5, 2, 9, 1, 5, 6]
    print('原始数组:', data)
    print('排序后:', bubble_sort(data.copy()))
