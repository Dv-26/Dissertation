#zigzag扫描类
class Zigzag:
    def __init__(self, width, height) -> None:
        self.width = width
        self.height = height
        self.x = 0
        self.y = 0

    def updatePos(self):
        # 如果到达右下角，返回 False 表示结束
        if self.x >= self.width - 1 and self.y >= self.height - 1:
            return False

        # 定义移动方向
        def left():
            self.x = max(self.x - 1, 0)
        def right():
            self.x = min(self.x + 1, self.width - 1)
        def up():
            self.y = max(self.y - 1, 0)
        def down():
            self.y = min(self.y + 1, self.height - 1)

        # Zigzag 移动逻辑
        if (self.y + self.x) % 2 == 0:  # 向上移动
            if self.y == 0 or self.x == self.width - 1:
                if self.x == self.width - 1:
                    down()
                else:
                    right()
            else:
                up()
                right()
        else:  # 向下移动
            if self.x == 0 or self.y == self.height - 1:
                if self.y == self.height - 1:
                    right()
                else:
                    down()
            else:
                down()
                left()

        return True

# 普通扫描类
class Horizontal:
    def __init__(self, width, height) -> None:
        self.width = width
        self.height = height
        self.x = 0
        self.y = 0

    def updatePos(self):
        if self.x >= self.width - 1 and self.y >= self.height - 1:
            return False
        if self.y == self.height - 1 :
            self.y = 0
            if self.x < self.width - 1 :
                self.x = self.x + 1
        else:
            self.y = self.y + 1
        return True

row = 8
col = 8
delay = 0
while delay < row * col:
    zigzag = Zigzag(row, col)
    horizontal = Horizontal(row, col)
    count = 0
    bitmap = [[False for _ in range(col)] for _ in range(row)]
    while horizontal.updatePos():
        bitmap[horizontal.y][horizontal.x] = True
        if count < delay :
            count = count + 1
        else:
            zigzag.updatePos()
            if not bitmap[zigzag.y][zigzag.x]:
                break

    if not horizontal.updatePos():
        break
    else:
        delay = delay + 1

print("zigzag的最少延迟时间: ", delay)

