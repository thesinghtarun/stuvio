package com.singhtarun.stuvio

import android.graphics.*
import android.view.View
import android.content.res.Resources

class FileCardDragShadowBuilder(
    private val fileName: String
) : View.DragShadowBuilder() {

    private val density = Resources.getSystem().displayMetrics.density

    private val width = (280 * density).toInt()
    private val height = (78 * density).toInt()

    private val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
    }

    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(45, 0, 0, 0)
        maskFilter = BlurMaskFilter(24f, BlurMaskFilter.Blur.NORMAL)
    }

    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#6750A4")
    }

    private val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.BLACK
        textSize = 16f * density
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }

    private val subtitlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.GRAY
        textSize = 13f * density
    }

    override fun onProvideShadowMetrics(
        outShadowSize: Point,
        outShadowTouchPoint: Point
    ) {

        outShadowSize.set(width, height)

        outShadowTouchPoint.set(
            width / 2,
            height / 2
        )
    }

    override fun onDrawShadow(canvas: Canvas) {

        val rect = RectF(
            10f,
            10f,
            width - 10f,
            height - 10f
        )

        canvas.drawRoundRect(
            rect,
            22f * density,
            22f * density,
            shadowPaint
        )

        canvas.drawRoundRect(
            rect,
            22f * density,
            22f * density,
            cardPaint
        )

        val iconRect = RectF(
            24f * density,
            16f * density,
            64f * density,
            56f * density
        )

        canvas.drawRoundRect(
            iconRect,
            12f * density,
            12f * density,
            iconPaint
        )

        val pdfPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 15f * density
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
        }

        canvas.drawText(
            "PDF",
            iconRect.centerX(),
            iconRect.centerY() + 6 * density,
            pdfPaint
        )

        canvas.drawText(
            fileName.take(28),
            80f * density,
            34f * density,
            titlePaint
        )

        canvas.drawText(
            "StudyVault",
            80f * density,
            56f * density,
            subtitlePaint
        )
    }
}